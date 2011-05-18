class MolecularAssaysController < ApplicationController
  #load_and_authorize_resource (# can't use because create method has array of molecular_assays instead of assay)
  
  before_filter :dropdowns, :only => [:new, :edit, :populate_assays]
  before_filter :query_dropdowns, :only => :query_params
  
  # GET /molecular_assays
  def index
    authorize! :read, MolecularAssay
    @molecular_assays = MolecularAssay.find(:all, :include => {:processed_sample => :sample},          
                                            :order => 'samples.patient_id, molecular_assays.barcode_key')
    render :action => 'index'
  end
  
  def list_added
    authorize! :read, MolecularAssay
    @molecular_assays = MolecularAssay.find_all_by_id(params[:assay_id].to_a, :include => {:processed_sample => :sample},
                                                        :order => 'molecular_assays.barcode_key')
    render :action => 'list_added'
  end
  
  # GET /molecular_assays/1
  def show
    @molecular_assay = MolecularAssay.find(params[:id], :include => [:processed_sample, :protocol])
    authorize! :read, @molecular_assay
  end
  
  # GET /molecular_assays/new
  def new
    authorize! :create, MolecularAssay
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
  end

  # GET /molecular_assays/1/edit
  def edit
    @molecular_assay = MolecularAssay.find(params[:id], :include => :processed_sample)
    authorize! :edit, @molecular_assay
    
    # Add existing owner to owner/researcher drop-down list (for case where current owner is inactive)
  end
  
  # Used to populate rows of molecular assays/samples to be entered 
  def populate_assays
    @new_assay = []; @processed_sample = [];
    params[:nr_assays] ||= 4  
    
    0.upto(params[:nr_assays].to_i - 1) do |i|
      @new_assay[i]    = MolecularAssay.new(params[:assay_default])
      @processed_sample[i] = @new_assay[i].processed_sample
    end
    render :partial => 'assay_sample_form'
    #render :action => :debug
  end

  def create_assays
    authorize! :create, MolecularAssay
    @new_assay = []; @assay_id = [];
    @assay_index = 0; assays_created = 0;
    
    #***** Assays are created as a transaction - either all created or none ****#
    #***** otherwise when error occurs with one assay, all assays are created again, resulting in duplicates ****#
    MolecularAssay.transaction do 
    0.upto(params[:nr_assays].to_i - 1) do |i|
      @new_assay[i] = build_assay(params['molecular_assay_' + i.to_s], params[:assay_default])
      if !@new_assay[i].nil?
        @assay_index = i
        @new_assay[i].save! 
        @assay_id.push(@new_assay[i].id)
        assays_created += 1
      end
    end
    end
    
    if assays_created == 0  # No valid assays were created
      flash[:error] = 'No assay(s) created - no source DNA fields entered'
      @assay_with_error = nil
      reload_defaults(params, params[:nr_assays])
      render :action => 'new'
      #render :action => 'debug'
    else
      flash[:notice] = assays_created.to_s + ' assay(s) successfully created'
      redirect_to :action => 'list_added', :assay_id => @assay_id
      #render :action => :debug
    end
    
    # Validation error(s)
    rescue ActiveRecord::ActiveRecordError
      flash.now[:error] = 'Error creating molecular assays - please enter all required fields'
      @assay_with_error = @new_assay[@assay_index]
      reload_defaults(params, params[:nr_assays])
      render :action => 'new'
      #render :action => :debug
  end
  
  # PUT /molecular_assays/1
  def update    
    @molecular_assay = MolecularAssay.find(params[:id])
    authorize! :update, @molecular_assay
    
    if @molecular_assay.update_attributes(params[:molecular_assay])
      flash[:notice] = 'Molecular assay was successfully updated.'
      redirect_to(@molecular_assay) 
    else
      dropdowns
      render :action => 'edit' 
    end
  end

  # DELETE /molecular_assays/1
  def destroy
    @molecular_assay = MolecularAssay.find(params[:id])
    authorize! :delete, MolecularAssay
    
    @molecular_assay.destroy
    redirect_to(molecular_assays_url) 
  end
  
  def auto_complete_for_barcode_key
    @molecular_assays = MolecularAssay.find(:all, :conditions => ["barcode_key LIKE ?", params[:search] + '%'])
    render :inline => "<%= auto_complete_result(@molecular_assays, 'barcode_key') %>"
  end
  
  def auto_complete_for_extraction_barcode
    @processed_samples = ProcessedSample.barcode_search(params[:search])
    if !params[:assay][:protocol_id].blank?
      protocol = Protocol.find(params[:assay][:protocol_id])
      if protocol
        molecule_type = protocol.molecule_type
        @processed_samples.reject! {|psample| psample.barcode_key[-3,1] != molecule_type} if ['D','R'].include?(molecule_type)
      end
    end
    render :inline => "<%= auto_complete_result(@processed_samples, 'barcode_key') %>"
  end
  
#  def populate_vol
#     @vol = params[:vol]
#     render :inline => "<%= @vol %>"
#     render :update do |page|
#        page['default_vol'].value = @vol
#        page['molecular_assay_1_volume'].value = @vol
#      end
#  end

#  def calc_vol
#    i = params[:i]
#    render :update do |page|
#      page.replace_html "sample_vol_#{i}", params[:assay_vol]
#      page.replace_html "buffer_vol_#{i}", 8888
#    end
#  end
  
  def update_fields
    params[:i] ||= 0
    if params[:source_sample_name]
      @processed_sample = ProcessedSample.find_by_barcode_key(params[:source_sample_name])
    end
    
    if @processed_sample.nil?
      render :nothing => true
    else
      render :update do |page|
        i = params[:i]
        page.replace_html "psample_vol_#{i}", @processed_sample.final_vol
        page.replace_html "psample_conc_#{i}", @processed_sample.final_conc
      end
    end
  end
  
protected
  def dropdowns
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('M')
  end
  
  def reload_defaults(params, nr_assays)
    dropdowns
    @assay_default = MolecularAssay.new(params[:assay_default])
    @new_assay = []   if !@new_assay
    @source_barcode = []; @processed_sample = []; 
    
    0.upto(nr_assays.to_i - 1) do |i|
      @new_assay[i] ||= MolecularAssay.new(params['molecular_assay_' + i.to_s].merge!(params[:assay_default]))
      @processed_sample[i] = @new_assay[i].processed_sample
    end
  end
  
  def build_assay(assay_param, assay_defaults)
    if assay_param[:source_sample_name].blank?
      return nil
      
    else
      molecular_assay = MolecularAssay.new(assay_param.merge!(assay_defaults))
      return molecular_assay
    end   
  end
  
end