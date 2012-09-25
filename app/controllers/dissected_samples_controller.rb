class DissectedSamplesController < ApplicationController
  
  before_filter :dropdowns, :only => :edit
  
  def new_params  
  end
  
  # GET /dissected_samples/new
  def new
    authorize! :create, Sample
    
    if params[:source_sample_id]
      @source_sample = Sample.find(params[:source_sample_id], :include => :histology)
    else
      @source_sample = Sample.find_by_barcode_key(params[:barcode_key], :include => :histology)
    end 
    
    if !@source_sample.nil?
      prepare_for_render_new(@source_sample.id)
      sample_params = {:barcode_key      => @sample_barcode,
                       :source_sample_id => @source_sample.id,
                       :amount_uom       => 'Weight (mg)',
                       :sample_date      => Date.today}
      @sample = Sample.new(sample_params)  
      @sample.build_sample_storage_container
    else
      flash[:error] = 'Sample barcode not found, please try again'
      redirect_to :action => 'new_params'
    end
  end
  
  def edit
    @sample = Sample.find(params[:id])
    @source_sample = Sample.find(@sample.source_sample_id, :include => :sample_characteristic)
  end
  
  def update
    @sample        = Sample.find(params[:id])
    @source_sample = Sample.find(@sample.source_sample_id)
    
    if @sample.update_attributes(params[:sample])
      @source_sample.update_attributes(:sample_remaining => params[:source_sample][:sample_remaining]) if params[:source_sample]
      flash[:notice] = 'Dissected sample was successfully updated'
      redirect_to(@sample)
    else
      flash[:error] = 'Error updating dissected sample'
      redirect_to :action => 'edit'
    end
  end
  
  # POST /dissected_samples
  def create
    authorize! :create, Sample
    
    params[:sample].merge!(:amount_rem => params[:sample][:amount_initial].to_f)
    @sample        = Sample.new(params[:sample])
    @source_sample = Sample.find(params[:sample][:source_sample_id])

    if @sample.save
      @source_sample.update_attributes(:sample_remaining => params[:source_sample][:sample_remaining]) if params[:source_sample]
      flash[:notice] = 'Sample successfully created'
      redirect_to samples_list1_path(:source_sample_id => params[:sample][:source_sample_id], :add_new => 'yes')
    else
      prepare_for_render_new(params[:sample][:source_sample_id])
      render :action => "new" 
    end
  end
  
protected
  def prepare_for_render_new(source_sample_id)
    # Find source sample, and sample characteristic associated with new (dissected) sample
    @source_sample    = Sample.find_by_id(source_sample_id)
    @sample_characteristic = SampleCharacteristic.find_by_id(@source_sample.sample_characteristic_id)
    
    # Determine next increment number for barcode suffix
    @sample_barcode = Sample.next_dissection_barcode(source_sample_id, @source_sample.barcode_key)
    
    # populate drop-down lists
    dropdowns
  end
  
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample']])
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure') 
    @sample_units       = category_filter(@category_dropdowns, 'sample unit')
    @vial_types         = category_filter(@category_dropdowns, 'vial type')
    @containers         = category_filter(@category_dropdowns, 'container')
    @freezer_locations  = FreezerLocation.list_all_by_room
  end
end
