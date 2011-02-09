class UsersController < ApplicationController
  ## cancan
  load_and_authorize_resource
  
  ## declarative_authorization ##
  #filter_access_to [:new, :create, :index]
  #filter_access_to [:edit, :update, :show], :attribute_check => true
  
  ## role_authorization ##
  #skip_before_filter :login_required, :only => [:new, :create]
  #require_role "admin", :for_all_except => [:new, :create]

  # render index.rhtml
  def index
    @users = current_user.find_all_with_authorization
  end

  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    
    if @user.errors.empty?
      #  Not populating roles.  Need to change this to @user.roles.build with parameters. 
      #  Change in OligoDB also.
      if Role::DEFAULT_ROLE
        role_id = Role.find_by_name(Role::DEFAULT_ROLE).id if Role::DEFAULT_ROLE
        @user.roles = Role.find(:all, :conditions => ["id = ?", role_id])
      end      
      
	    @user.save
      self.current_user = @user
      #Authorization::current_user = @user   # for declarative_authorization #
      redirect_to('/')
      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end
  
  # render edit.html
  def edit 
    @user = User.find(params[:id])
    @roles = Role.find(:all)
  end
  
  def update
    params[:user][:role_ids] ||= []
 
    @user = User.find(params[:id])
    
    if can? :edit, Role
      @user.roles = Role.find(params[:user][:role_ids])
    end
    
    if DEMO_APP && DEMO_USERS.include?(current_user.login)
      flash.now[:error] = "Change functionality disabled for default user logins in demo application"
      @roles = Role.find(:all)
      render :action => 'edit'
      
    elsif current_user.has_role?("admin") || @user.authenticated?(params[:curr_user][:current_password])
      if @user.update_attributes(params[:user])
        flash[:notice] = "User has been updated"
        redirect_to users_url
      else
        flash.now[:error] = "Error updating user"
        @roles = Role.find(:all)
        render :action => 'edit'
      end
      
    else
      flash.now[:error] = "Incorrect current password entered - please try again"
      @roles = Role.find(:all)
      render :action => 'edit'
    end
  end
  
  # DELETE /users/1
  def destroy
    if DEMO_APP && DEMO_USERS.include?(current_user.login)
      flash[:error] = "Delete functionality disabled for default user logins in demo application"
      redirect_to users_url
      
    else
      @user = User.find(params[:id])
      @user.destroy
      redirect_to(users_url) 
    end
  end
  
  def forgot
    if request.post?
      user = User.find_by_email(params[:user][:email])
      if user
        user.create_reset_code
        flash[:notice] = "Reset code sent to #{user.email}"
      else
        flash[:notice] = "#{params[:user][:email]} does not exist in system"
      end
    render :action => :display_message
    end
  end
  
  def reset
    @user = User.find_by_reset_code(params[:reset_code]) unless params[:reset_code].nil?
    if request.post?
      if @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
        self.current_user = @user
        @user.delete_reset_code
        flash[:notice] = "Password reset successfully for #{@user.email} - You are now logged in"
        redirect_to :controller => :welcome, :action => :index
      else
        render :action => :reset
      end
    end
  end
    
end