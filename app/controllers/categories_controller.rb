class CategoriesController < ApplicationController
  load_and_authorize_resource
  
  # GET /categories
  def index
    @categories = Category.find_and_sortby_cgroup
  end

  # GET /categories/1
  def show
    @category = Category.includes(:category_values).order('category_values.c_position').find(params[:id])
  end

  # GET /categories/new
  def new
    @category = Category.new
    6.times {@category.category_values.build}
  end

  # GET /categories/1/edit
  def edit
    @category = Category.includes(:category_values).order('category_values.c_position').find(params[:id])
  end

  # POST /categories
  def create
    @category = Category.new(params[:category].merge!(:cgroup_id => 8))
    
    if @category.save
      flash[:notice] = 'Category and values were successfully created.'
      redirect_to(@category)
    else
      render :action => "new" 
    end
  end

  # PUT /categories/1
  def update
    
    @category = Category.find(params[:id])
    if @category.update_attributes(params[:category])
      
      # Delete any category value records which were removed/deleted from edit screen
      params[:category][:category_values_attributes].each do |ckey, cattrs|
        CategoryValue.destroy(cattrs[:id]) if cattrs[:c_value].blank?
      end
      
      flash[:notice] = "Successfully updated category and values"
      redirect_to(@category)
    else
      render :action => 'edit'
    end
    
  end

  # DELETE /categories/1
  def destroy
    @category = Category.find(params[:id])
    @category.destroy

    redirect_to(categories_url)
    end
end
