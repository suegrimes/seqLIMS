class SampleStorageContainersController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => :new_query

  # GET /sample_storage_containers/1/edit
  def edit
    @sample_storage_container = SampleStorageContainer.find(params[:id])
    render :action => 'edit'
  end

  # PUT /sample_storage_containers/1
  def update
    @sample_storage_container = SampleStorageContainer.find(params[:id])

    if @sample_storage_container.update_attributes(params[:sample_storage_container])
      flash[:notice] = 'Sample storage container was successfully updated.'
      redirect_to :action => :details, :ss_container_id => @sample_storage_container.id
    else
      dropdowns
      flash[:error] = 'ERROR - Unable to update sample storage container'
      render :action => 'edit'
    end
  end

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

  def export_container
    export_type = 'T'
    @sample_storage_containers = SampleStorageContainer.find_for_export(params[:export_id])
    file_basename = ['LIMS_Sample_Containers', Date.today.to_s].join("_")

    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_container_csv(@sample_storage_containers)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')

      else # Use for debugging
        csv_string = export_container_csv(@sample_storage_containers)
        render :text => csv_string
    end
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

  def export_container_csv(sample_containers)
    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << %w{DownloadDt Room_Freezer ContainerType ContainerName Position SampleType Barcode}

      sample_containers.each do |scontainer|
        csv << [Date.today.to_s, scontainer.room_and_freezer, scontainer.container_type, scontainer.container_name,
                scontainer.position_in_container, scontainer.type_of_sample, scontainer.sample_name_or_barcode]
      end
    end
    return csv_string
  end

end
