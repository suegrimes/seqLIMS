class SeqLibsController < ApplicationController
  #load_and_authorize_resource (# can't use because create method for singleplex lib has array of seq_libs instead of single lib)
  
  before_filter :dropdowns, :only => [:new, :edit, :populate_libs]
  before_filter :query_dropdowns, :only => :query_params
  
  # Added to avoid Invalid Authenticity token errors when calling these methods to refresh form
  # (Probably can fix this by specifying method => get when calling these methods)
  #skip_before_filter :verify_authenticity_token, :only => [:populate_libs]
 
  # GET /seq_libs
  def index
    authorize! :read, SeqLib
    if params[:lib_id]
      @seq_libs = SeqLib.find_all_by_id(params[:lib_id].to_a, :order => 'seq_libs.preparation_date DESC')
    else
      @seq_libs = SeqLib.find(:all, :order => 'seq_libs.preparation_date DESC')
    end
    render :action => 'index'
  end
  
  # GET /seq_libs/1
  def show
    @seq_lib = SeqLib.find(params[:id], :include => [{:lib_samples => :splex_lib}, :attached_files])
    @protocol = Protocol.find(@seq_lib.protocol_id) if @seq_lib.protocol_id
    authorize! :read, @seq_lib
  end
  
  # GET /seq_libs/new
  def new
    authorize! :create, SeqLib
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @lib_default = SeqLib.new(:alignment_ref_id => AlignmentRef.default_id)
    render :action => 'new'
  end

  # GET /seq_libs/1/edit
  def edit
    @seq_lib = SeqLib.find(params[:id], :include => :lib_samples)
    authorize! :edit, @seq_lib
    # ToDo:  Add existing owner to drop-down list if he/she is inactive
    
    if @seq_lib.library_type == 'M'
      redirect_to :controller => 'mplex_libs', :action => :edit, :id => params[:id]
    else
      render :action => 'edit'
    end
  end
  
  # Used to populate rows of libraries/samples to be entered for singleplex libraries
  def populate_libs
    @new_lib = []
    @lib_samples = []
    params[:nr_libs] ||= 4
    
    0.upto(params[:nr_libs].to_i - 1) do |i|
      @new_lib[i]    = SeqLib.new(params[:lib_default])
      @lib_samples[i] = LibSample.new(:source_DNA => params[:sample_default][:source_DNA],
                                      :enzyme_code => array_to_string(params[:sample_default][:enzyme_code]))
    end
    render :partial => 'sample_form'
    #render :action => :debug
  end

  def create
    authorize! :create, SeqLib
    @new_lib = []; @lib_id = [];
    @lib_index = 0; libs_created = 0
    
    #***** Libraries are created as a transaction - either all created or none ****#
    #***** otherwise when error occurs with one library, all libraries are created again, resulting in duplicates ****#
    SeqLib.transaction do 
    0.upto(params[:nr_libs].to_i - 1) do |i|
      lib_param = params['seq_lib_' + i.to_s]
      sample_param = params['lib_sample_' + i.to_s]
      @new_lib[i] = build_simplex_lib(lib_param, sample_param)
      if !@new_lib[i][:lib_name].blank?
        @lib_index = i
        @new_lib[i].save! 
        @lib_id.push(@new_lib[i].id)
        libs_created += 1
      end
    end
    end
    
    if libs_created == 0  # All lib_names were blank
      flash[:error] = 'No sequencing library(ies) created - no non-blank library names found'
      @lib_with_error = nil
      reload_lib_defaults(params, params[:nr_libs])
      render :action => 'new'
      #render :action => 'debug'
    else
      flash[:notice] = libs_created.to_s + ' sequencing library(ies) successfully created'
      redirect_to :action => 'index', :lib_id => @lib_id
      #render :action => :debug
    end
    
    # Validation error(s)
    rescue ActiveRecord::ActiveRecordError
      flash.now[:error] = 'Error creating sequencing library -please enter all required fields'
      @lib_with_error = @new_lib[@lib_index]
      reload_lib_defaults(params, params[:nr_libs])
      render :action => 'new'
      #render :action => :debug
  end
  
  # PUT /seq_libs/1
  def update
    #params[:seq_lib][:existing_sample_attributes] ||= {}
    
    @seq_lib = SeqLib.find(params[:id])
    authorize! :update, @seq_lib
    
    pool_label = Pool.get_pool_label(params[:seq_lib][:pool_id])
    alignment_key = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])
    params[:seq_lib].merge!(:alignment_ref => alignment_key,
                            :oligo_pool => pool_label)
    params[:seq_lib][:lib_samples_attributes]["0"][:runtype_adapter] = params[:seq_lib][:runtype_adapter]
    
    if @seq_lib.update_attributes(params[:seq_lib])
      SeqLib.upd_oligo_pool(@seq_lib) #if @seq_lib.oligo_pool_changed?
      FlowLane.upd_lib_lanes(@seq_lib)
      flash[:notice] = 'Sequencing library was successfully updated.'
      redirect_to(@seq_lib) 
    else
      flash[:error] = 'ERROR - Unable to update sequencing library'
      dropdowns
      render :action => 'edit' 
    end
  end

  # DELETE /seq_libs/1
  def destroy
    # to delete seq_lib, need to first delete associated lib_samples
    # make this an admin only function in production
    @seq_lib = SeqLib.find(params[:id])
    authorize! :destroy, @seq_lib
    
    @seq_lib.destroy
    redirect_to(seq_libs_url) 
  end
  
  def auto_complete_for_barcode_key
    @seq_libs = SeqLib.find(:all, :conditions => ["barcode_key LIKE ?", params[:search] + '%'])
    render :inline => "<%= auto_complete_result(@seq_libs, 'barcode_key') %>"
  end
  
protected
  def dropdowns
    @adapters     = Category.populate_dropdown_for_category('run_type')
    @enzymes      = Category.populate_dropdown_for_category('enzyme')
    @align_refs   = AlignmentRef.populate_dropdown
    @oligo_pools  = Pool.populate_dropdown('lib')
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('L')
    @quantitation= Category.populate_dropdown_for_category('quantitation')
  end
  
  def reload_lib_defaults(params, nr_libs)
    dropdowns
    @lib_default = SeqLib.new(params[:lib_default])
    @sample_default = LibSample.new(params[:sample_default])
   
    @new_lib = []     if !@new_lib
    @lib_samples = [] if !@lib_samples
    
    0.upto(nr_libs.to_i - 1) do |i|
      @new_lib[i] ||= SeqLib.new(params['seq_lib_' + i.to_s])
      @lib_samples[i] = LibSample.new(params['lib_sample_' + i.to_s])
    end
  end
  
  def build_simplex_lib(lib_param, sample_param)
     lib_param.merge!(:library_type => 'S',
                      :oligo_pool => Pool.get_pool_name(lib_param[:pool_id]),
                      :alignment_ref => AlignmentRef.get_align_key(lib_param[:alignment_ref_id]))
     seq_lib = SeqLib.new(lib_param)
     
     sample_param.merge!(:sample_name     => lib_param[:lib_name],
                         :runtype_adapter => lib_param[:runtype_adapter],
                         :notes           => lib_param[:notes])
     seq_lib.lib_samples.build(sample_param)
     return seq_lib
  end
 
end