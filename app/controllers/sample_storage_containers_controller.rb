class SampleStorageContainersController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query   
  end
  
  def index
    @sample_storage_containers = SampleStorageContainer.find(:all, :order => "container_type, container_name, position_in_container",
                                                             :conditions => ["container_type = ? AND container_name = ?", 'Rack', '01'])                                 
    render :action => :index
  end
  
protected
  def dropdowns
    @container_types  = SampleStorageContainer.populate_dropdown
  end
end

