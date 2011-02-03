class SeqLibsController < ApplicationController
  #load_and_authorize_resource (# can't use because create method for singleplex lib has array of seq_libs instead of single lib)
  
  before_filter :dropdowns, :only => [:new, :edit, :populate_mplex, :populate_splex]
  before_filter :query_dropdowns, :only => :query_params
  
  # Added to avoid Invalid Authenticity token errors when calling these methods to refresh form
  # (Probably can fix this by specifying method => get when calling these methods)
  skip_before_filter :verify_authenticity_token, :only => [:populate_splex, :populate_mplex]
 
  # GET /seq_libs
  def index
    unauthorized! if cannot? :read, SeqLib
    if params[:lib_id]
      @seq_libs = SeqLib.find_all_by_id(params[:lib_id].to_a, :order => 'seq_libs.preparation_date DESC')
    else
      @seq_libs = SeqLib.find(:all, :order => 'seq_libs.preparation_date DESC')
    end
    render :action => 'index'
  end
  
  # GET /seq_libs/1
  def show
    @seq_lib = SeqLib.find(params[:id], :include => :lib_samples)
    @protocol = Protocol.find(@seq_lib.protocol_id) if @seq_lib.protocol_id
    unauthorized! if cannot? :read, @seq_lib
  end
  
  # GET /seq_libs/new
  def new
    unauthorized! if cannot? :create, SeqLib
    
    params[:multiplex] ||= 'single'
    @seq_lib = SeqLib.new(:preparation_date => Date.today)
    
    if params[:multiplex] == 'single'
      @adapters.reject! {|adapter| adapter.c_value[0,1] == 'M'}
      render :action => 'new_splex'
    else
      @adapters.reject! {|adapter| adapter.c_value[0,1] == 'S'}
      render :action => 'new_mplex'      
    end  
  end

  # GET /seq_libs/1/edit
  def edit
    @seq_lib = SeqLib.find(params[:id], :include => :lib_samples)
    unauthorized! if cannot? :edit, @seq_lib
    
    # Add existing owner to owner/researcher drop-down list (for case where current owner is inactive)
  end
  
  # Used to populate rows of libraries/samples to be entered for singleplex libraries
  def populate_splex
    @new_lib = []
    @lib_samples = []
    params[:nr_libs] ||= 4
    params[:lib_default][:enzyme_code] = array_to_string(params[:lib_default][:enzyme_code])   
    
    0.upto(params[:nr_libs].to_i - 1) do |i|
      @new_lib[i]    = SeqLib.new(params[:lib_default])
      @lib_samples[i] = LibSample.new(:source_DNA => params[:sample_default][:source_DNA])
    end
    render :partial => 'splex_sample_form'
    #render :action => :debug
  end

  def create_splex
    unauthorized! if cannot? :create, SeqLib
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
      reload_splex_defaults(params, params[:nr_libs])
      render :action => 'new_splex'
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
      reload_splex_defaults(params, params[:nr_libs])
      render :action => 'new_splex'
      #render :action => :debug
  end
  
  # Used to populate rows of samples to be entered for a multiplex library
  def populate_mplex
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
    render :partial => 'mplex_sample_form'
  end
  
  def create_mplex
    unauthorized! if cannot? :create, SeqLib
    #lib_params = params[:seq_lib]; sample_params = params[:lib_samples]
      
    @seq_lib, samples_built = build_multiplex_lib(params[:seq_lib], params[:lib_samples])
    
    if samples_built == 0
      flash.now[:error] = 'No sequencing library created - please enter one or more samples'
      reload_mplex_defaults(params[:seq_lib], params[:lib_samples])
      render :action => 'new_mplex'
    else 
      @seq_lib.save!
      flash[:notice] = 'Multiplex library with ' + samples_built.to_s + ' samples, successfully created'
      redirect_to :action => 'show', :id => @seq_lib.id
    end
    
    # Validation error(s)
    rescue ActiveRecord::ActiveRecordError
      flash.now[:error] = 'Error creating sequencing library -please enter all required fields'
      @lib_with_error = @seq_lib
      reload_mplex_defaults(params[:seq_lib], params[:lib_samples], 'multi')
      render :action => 'new_mplex'
  end
  
  # PUT /seq_libs/1
  def update
    params[:seq_lib][:existing_sample_attributes] ||= {}
    
    @seq_lib = SeqLib.find(params[:id])
    unauthorized! if cannot? :update, @seq_lib
    
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

  # DELETE /seq_libs/1
  def destroy
    # to delete seq_lib, need to first delete associated lib_samples
    # make this an admin only function in production
    @seq_lib = SeqLib.find(params[:id])
    unauthorized! if cannot? :delete, SeqLib
    
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
    @projects     = Category.populate_dropdown_for_category('project')
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('L')
    # Delete target_pools, and drop table - not needed (replaced by project)
    #@target_pools = TargetPool.find(:all, :order => :pool_name)
    @quantitation= Category.populate_dropdown_for_category('quantitation')
  end
  
  def reload_splex_defaults(params, nr_libs)
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
  
  def reload_mplex_defaults(lib_params, sample_params)
    dropdowns
    
    @tag_seqs = []
    0.upto(sample_params.size - 1) {|i| @tag_seqs[i] = IndexTag.find_or_blank(lib_params[:runtype_adapter], i+1)}
    
    @lib_samples = []
    sample_params.each {|sample| @lib_samples.push(LibSample.new(sample))} 
  end
  
  def build_simplex_lib(lib_param, sample_param)
     lib_param.merge!(:alignment_ref => AlignmentRef.get_align_key(lib_param[:alignment_ref_id]))
     seq_lib = SeqLib.new(lib_param)
     
     sample_param.merge!(:sample_name     => lib_param[:lib_name],
                         :multiplex_type  => lib_param[:runtype_adapter],
                         :target_pool     => lib_param[:target_pool],
                         :enzyme_code     => lib_param[:enzyme_code],
                         :notes           => lib_param[:notes])
     seq_lib.lib_samples.build(sample_param)
     return seq_lib
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
        
      seq_lib.lib_samples.build(ls)
      samples_built += 1
    end
    
    return seq_lib, samples_built
  end
  
end