class PreparedSamplesController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new, :edit]
  
#  def index
#    @prepared_samples = PreparedSample.find_all_incl_extracted
#  end

  def show
    @prepared_sample = PreparedSample.find(params[:id], :include => :attached_files)
  end

  # GET /prepared_samples/new
  def new
    # Find extracted sample from which this sample will be prepared
    @processed_sample = ProcessedSample.find(params[:processed_sample_id], :include => :sample)
    
    # Find samples already prepared from this extracted sample, and get generate next sequential barcode
    @prep_barcode = PreparedSample.next_preparation_barcode(@processed_sample.id, @processed_sample.barcode_key)
    
    # Populate barcode and date for new processed sample
    @prepared_sample = PreparedSample.new(:barcode_key => @prep_barcode,
                                          :preparation_date => Date.today)
    
    render :action => 'new'
  end

  def edit
    @prepared_sample = PreparedSample.find(params[:id], :include => {:processed_sample => :sample})
    @attached_file   = AttachedFile.new
  end

# POST /prepared_samples
  def create
    @prepared_sample  = PreparedSample.new(params[:prepared_sample])
    @processed_sample = ProcessedSample.find(params[:prepared_sample][:processed_sample_id])
    
    ProcessedSample.transaction do
      @prepared_sample.save!
      if params[:prepared_sample][:input_amount]
        @processed_sample.amount_rem -= params[:processed_sample][:input_amount].to_f
        @processed_sample.save!
      end
      flash[:notice] = 'Prepared sample was successfully created'
      redirect_to :action => :edit, :id => @prepared_sample.id
    end

  rescue ActiveRecord::RecordInvalid
      dropdowns
      flash[:notice] = 'Error adding prepared sample - Please contact system admin'
      render :action => "new"
  end
  
  def upload_file
    @attached_file = AttachedFile.new(params[:attached_file])
    @attached_file.sampleproc = PreparedSample.find_by_id(params[:prepared_sample_id])
    if @attached_file.save
      flash[:notice] = 'Attached file successfully saved'
      redirect_to :action => 'show', :id => params[:prepared_sample_id]  
    else
      flash.now[:error] = 'Error saving attached file'
      dropdowns
      @prepared_sample = PreparedSample.find(params[:prepared_sample_id])
      render :action => 'edit'
    end  
  end

protected
  def dropdowns
    @protocols         = Protocol.find_for_protocol_type('P')
    @storage_locations = StorageLocation.list_all_by_room
  end
end
