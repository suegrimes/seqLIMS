class SampleStorageContainersController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query   
  end
  
  def index
    @freezer = FreezerLocation.find(params[:freezer_location][:freezer_location_id])
    condition_array = define_conditions(params)
    @sample_storage_containers = SampleStorageContainer.find_for_query(condition_array)
    @ss_containers = @sample_storage_containers.group_by {|ssc| [ssc.freezer_location_id, ssc.container_type, ssc.container_sort]}
    render :action => :index
  end

  def details
    @ssc = SampleStorageContainer.find(params[:ss_container_id])
    @ss_containers = SampleStorageContainer.where('freezer_location_id = ? AND container_type = ? AND container_name = ?',
                                                  @ssc.freezer_location_id, @ssc.container_type, @ssc.container_name)
    @sample_storage_containers = @ss_containers.sort_by {|sscontainer| [sscontainer.position_sort[0], sscontainer.position_sort[1]]}
    render :action => :details
  end

protected
  def dropdowns
    @freezers = FreezerLocation.populate_dropdown
    @container_types  = SampleStorageContainer.populate_dropdown
  end

  def define_conditions(params)
    @where_select = []
    @where_values = []

    unless param_blank?(params[:freezer_location][:freezer_location_id])
      @where_select.push('freezer_location_id = ?')
      @where_values.push(params[:freezer_location][:freezer_location_id])
    end

    if param_blank?(params[:container_type])
      @where_select.push('container_type IS NOT NULL')
    else
      @where_select.push('container_type = ?')
      @where_values.push(params[:container_type])
    end

    sql_where_clause = (@where_select.empty? ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end

end
