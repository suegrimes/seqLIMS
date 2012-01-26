class ProcessedSamplesController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new, :edit, :edit_by_barcode]
  
  # GET /processed_samples
  def index
    @processed_samples = ProcessedSample.find_all_incl_sample
  end
  
  def show_by_sample
    @processed_samples = ProcessedSample.find_all_by_sample_id(params[:sample_id])
    @sample  = Sample.find_by_id(params[:sample_id])
    render :action => 'index'
  end
  
  # GET /processed_samples/1
  def show
    @processed_sample = ProcessedSample.find(params[:id], 
                                       :include => [{:sample => {:sample_characteristic => :pathology}},
                                                    {:lib_samples => :seq_lib}, :molecular_assays, :sample_storage_container])
  end
  
  def new_params
    
  end
  
  # GET /processed_samples/new
  def new
    # Find sample from which processed sample will be extracted
    if params[:source_id]
      @sample = Sample.find(params[:source_id], :include => :sample_characteristic)
    else
      @sample = Sample.find_by_barcode_key(params[:barcode_key], :include => :sample_characteristic)
    end
    
    if @sample.nil?
      flash.now[:error] = 'Source sample barcode not found - please try again'
      render :action => 'new_params'
    
    #  proceed to new extraction screen if dissected sample barcode entered, or clinical sample has no dissections
    elsif @sample.clinical_sample == 'no' || Sample.find(:first, :conditions => ["samples.source_sample_id = ?", @sample.id]).nil?
    
      # Populate date and default volume for new processed sample
      @processed_sample = ProcessedSample.new(:processing_date => Date.today,
                                              :protocol_id => 12,
                                              :vial => '2ml',
                                              :final_vol => 50,
                                              :elution_buffer => 'TB')
      @processed_sample.build_sample_storage_container(:freezer_location_id => 1)
      render :action => 'new'
      
    else  # clinical sample with one or more dissections, so show list to select from
      @samples = Sample.find(:all, :conditions => ["samples.id = ? OR samples.source_sample_id = ?", @sample.id, @sample.id],
                                   :order => "samples.barcode_key")
      render :action => 'new_list'
    end
  end

  def edit_by_barcode
    @processed_sample = ProcessedSample.find_one_incl_patient(["processed_samples.barcode_key = ?", params[:barcode_key]])
    if @processed_sample
      @processed_sample.build_sample_storage_container if !@processed_sample.sample_storage_container
      render :action => :edit
    else
      flash[:error] = 'No entry found for extraction barcode: ' + params[:barcode_key]
      redirect_to :controller => :samples, :action => :edit_params
    end
  end
  
  # GET /processed_samples/1/edit
  def edit
    @processed_sample = ProcessedSample.find_one_incl_patient(["processed_samples.id = ?", params[:id]])
    @processed_sample.build_sample_storage_container if !@processed_sample.sample_storage_container
    render :action => 'edit'
    #render :action => 'debug'
  end

  # POST /processed_samples
  def create
    @processed_sample = ProcessedSample.new(params[:processed_sample])
    @sample = Sample.find(params[:processed_sample][:sample_id])
    
    Sample.transaction do
      @processed_sample.save!
      if params[:processed_sample][:input_amount]
        params[:sample].merge!(:amount_rem => @sample.amount_rem - params[:processed_sample][:input_amount].to_f)
      end
      @sample.update_attributes!(params[:sample])
      flash[:notice] = 'Processed sample was successfully created'
      redirect_to(:action => 'show_by_sample',
                  :sample_id => params[:processed_sample][:sample_id])
    end

  rescue ActiveRecord::RecordInvalid
      dropdowns
      flash[:notice] = 'Error adding processed sample - Please contact system admin'
      render :action => "new"
  end

  # PUT /processed_samples/1
  # PUT /processed_samples/1.xml
  def update
    @processed_sample = ProcessedSample.find(params[:id])
 
    ProcessedSample.transaction do
      @processed_sample.update_attributes!(params[:processed_sample])
      flash[:notice] = 'Processed sample successfully updated'
      redirect_to(@processed_sample)
    end

    rescue ActiveRecord::RecordInvalid
      render :action => "edit"
  end

  # DELETE /processed_samples/1
  def destroy
    @processed_sample = ProcessedSample.find(params[:id])
    @processed_sample.destroy
    
    redirect_to :action => :show_by_sample, :sample_id => @processed_sample.sample_id
  end
  
  def testing
    @sql_mask = mask_barcode('6451A.D01')
    render :action => 'debug'
  end
  
  def auto_complete_for_barcode_key
    @processed_samples = ProcessedSample.barcode_search(params[:search])
    render :inline => "<%= auto_complete_result(@processed_samples, 'barcode_key') %>"
  end

protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Extraction']])
    @extraction_type    = category_filter(@category_dropdowns, 'extraction type')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure')
    @support            = category_filter(@category_dropdowns, 'support')
    @elution_buffer     = category_filter(@category_dropdowns, 'elution buffer')
    @vial_vol           = category_filter(@category_dropdowns, 'vial volume')
    @protocols          = Protocol.find_for_protocol_type('E')  #Extraction protocols
    @containers         = category_filter(@category_dropdowns, 'container')
    @freezer_locations  = FreezerLocation.find(:all)
  end

 end