class SampleStorageContainersController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query   
  end
  
  def index
    @container_type = params[:container_type]
    if param_blank?(params[:container_name])
      flash[:error] = 'Please enter container name'
      dropdowns
      render :action => :new_query
    else
      @container_name = params[:container_name]
      @ss_containers = SampleStorageContainer.find(:all, :order => "container_type, container_name, position_in_container",
                                                       :conditions => ["container_type = ? AND container_name = ?", @container_type, @container_name])                                 
      @sample_storage_containers = @ss_containers.sort_by {|sscontainer| [sscontainer.position_sort[0], sscontainer.position_sort[1]]}
      render :action => :index
    end
  end
  
protected
  def dropdowns
    @container_types  = SampleStorageContainer.populate_dropdown
  end
end

