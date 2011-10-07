class MplexLibsController < ApplicationController
  load_and_authorize_resource :class => 'SeqLib'  
  before_filter :dropdowns, :only => [:new, :edit, :populate_libs]
  
  # GET /seq_libs/new
  def new
    authorize! :create, SeqLib
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    
    @seq_lib = SeqLib.new(:preparation_date => Date.today,
                          :owner => @requester,
                          :alignment_ref_id => AlignmentRef.default_id)
    @adapters.reject! {|adapter| adapter.c_value[0,1] == 'S'}
    render :action => 'new'      
  end

  # GET /seq_libs/1/edit
  def edit
    @seq_lib = SeqLib.find(params[:id], :include => :lib_samples)
    authorize! :edit, @seq_lib
    
    # Add existing owner to owner/researcher drop-down list (for case where current owner is inactive)
  end

  # Used to populate rows of samples to be entered for a multiplex library
  def populate_libs
    @seq_lib  = SeqLib.new(:preparation_date => Date.today,
                           :alignment_ref_id => params[:seq_lib][:alignment_ref_id])
    @lib_samples = []
    @tag_seqs = []
    params[:seq_lib][:enzyme_code] = array_to_string(params[:seq_lib][:enzyme_code])
    
    nr_samples = (params[:seq_lib][:runtype_adapter] == 'M_PE_Illumina' ? 
                         SeqLib::MILLUMINA_SAMPLES - 1 : SeqLib::MULTIPLEX_SAMPLES - 1)
    
    0.upto(nr_samples) do |i|
      @tag_seqs[i] = IndexTag.find_or_blank(params[:seq_lib][:runtype_adapter], i+1)
      @lib_samples[i] = LibSample.new(:multiplex_type => params[:seq_lib][:runtype_adapter],
                                      :target_pool    => params[:seq_lib][:target_pool],
                                      :enzyme_code    => params[:seq_lib][:enzyme_code],
                                      :source_DNA     => params[:lib_sample][:source_sample_name])
    end
    render :partial => 'sample_form'
  end
  
  def create
    authorize! :create, SeqLib
    #lib_params = params[:seq_lib]; sample_params = params[:lib_samples]
      
    @seq_lib, samples_built = build_multiplex_lib(params[:seq_lib], params[:lib_samples])
    
    if samples_built == 0
      flash.now[:error] = 'No sequencing library created - please enter one or more samples'
      reload_defaults(params[:seq_lib], params[:lib_samples])
      render :action => 'new'
    else 
      @seq_lib.save!
      flash[:notice] = 'Multiplex library with ' + samples_built.to_s + ' samples, successfully created'
      redirect_to(@seq_lib)
    end
    
    # Validation error(s)
    rescue ActiveRecord::ActiveRecordError
      flash.now[:error] = 'Error creating sequencing library -please enter all required fields'
      @lib_with_error = @seq_lib
      reload_defaults(params[:seq_lib], params[:lib_samples])
      render :action => 'new'
  end
  
  # PUT /seq_libs/1
  def update
    #params[:seq_lib][:existing_sample_attributes] ||= {}
    
    @seq_lib = SeqLib.find(params[:id])
    authorize! :update, @seq_lib
    
    alignment_key = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])
    params[:seq_lib].merge!(:alignment_ref => alignment_key)
    
    if @seq_lib.update_attributes(params[:seq_lib])
      FlowLane.upd_lib_lanes(@seq_lib)
      flash[:notice] = 'Sequencing library was successfully updated.'
      redirect_to(@seq_lib) 
    else
      dropdowns
      render :action => 'edit' 
    end
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
    @projects     = Category.populate_dropdown_for_category('project')
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('L')
    # Delete target_pools, and drop table - not needed (replaced by project)
    #@target_pools = TargetPool.find(:all, :order => :pool_name)
    @quantitation= Category.populate_dropdown_for_category('quantitation')
  end
  
  def reload_defaults(lib_params, sample_params)
    dropdowns
    
    @tag_seqs = []
    0.upto(sample_params.size - 1) {|i| @tag_seqs[i] = IndexTag.find_or_blank(lib_params[:runtype_adapter], i+1)}
    
    @lib_samples = []
    sample_params.each {|sample| @lib_samples.push(LibSample.new(sample))} 
  end
  
  def build_multiplex_lib(lib_params, sample_params)
    samples_built = 0
    
    if lib_params[:alignment_ref_id]
      lib_params.merge!(:alignment_ref => AlignmentRef.get_align_key(lib_params[:alignment_ref_id]))
    end
    lib_params[:enzyme_code] = array_to_string(lib_params[:enzyme_code])
    
    seq_lib = SeqLib.new(lib_params)
      
    sample_params.each_with_index do |ls, i|
      next if ls[:sample_name].blank?
      
      ls[:multiplex_type] = lib_params[:runtype_adapter]
      seq_lib.lib_samples.build(ls)
      samples_built += 1
    end
    
    return seq_lib, samples_built
  end
  
end