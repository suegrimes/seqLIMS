class MplexLibsController < ApplicationController
  #load_and_authorize_resource :class => 'SeqLib'  
  
  before_filter :dropdowns, :only => [:new, :edit]
  before_filter :setup_dropdowns, :only => :setup_params
  
  def setup_params
   @from_date = (Date.today - 3.months).beginning_of_month
   @to_date   =  Date.today
   @seq_lib   = SeqLib.new(:owner => (current_user.researcher ? current_user.researcher.researcher_name : nil))
  end
  
  # GET /seq_libs
  def index
    @seq_libs = SeqLib.find(:all, :include => :lib_samples, :conditions => ['library_type = ?', 'M'])
  end
  
  # GET /seq_libs/1
  def show
    @seq_lib = SeqLib.find(params[:id], :include => :lib_samples)
  end
 
  def new
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @seq_lib   = SeqLib.new(:library_type => 'M',
                            :owner => @requester,
                            :preparation_date => Date.today,
                            :alignment_ref_id => AlignmentRef.default_id)
    
    # Get sequencing libraries based on parameters entered
    @condition_array = define_lib_conditions(params)
    @singleplex_libs = SeqLib.find(:all, :include => :lib_samples,
                                   :conditions => @condition_array,
                                   :order => 'barcode_key, lib_name')
                                   
    # Populate lib_samples based on data in each sequencing library
    @lib_samples = []
    @singleplex_libs.reject!{|s_lib| s_lib.lib_samples[0].nil?}
    
    @singleplex_libs.each_with_index do |s_lib, i|
      @lib_samples[i] = LibSample.new(s_lib.lib_samples[0].attributes)
    end     
    
    render :action => 'new'
  end
  
  # GET /seq_libs/1/edit
  def edit
    @seq_lib = SeqLib.find(params[:id], :include => :lib_samples)
  end

  # POST /seq_libs
  def create_mplex
    @seq_lib       = SeqLib.new(params[:seq_lib])
    @seq_lib[:library_type] = 'M'
    @seq_lib[:alignment_ref] = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])
#    @seq_lib.save
#    render :action => :debug
    
    params[:lib_samples].each do |lib_sample|
      next if param_blank?(lib_sample[:splex_lib_id])
      
      splex_lib = SeqLib.find(lib_sample[:splex_lib_id], :include => :lib_samples)
      slib_sample = splex_lib.lib_samples[0].attributes
      slib_sample[:splex_lib_id] = splex_lib.id
      slib_sample[:splex_lib_barcode] = splex_lib.barcode_key

      @seq_lib.lib_samples.build(slib_sample)
    end
    
    if @seq_lib.save
      flash[:notice] = 'Multiplex library successfully created'
      redirect_to :action => :show, :id => @seq_lib.id
     
    else
      flash.now[:error] = 'ERROR - Unable to create multiplex library'
      slib_ids = params[:lib_samples].collect{|lib_sample| lib_sample[:splex_lib_id] if !param_blank?(lib_sample[:splex_lib_id])}
      #@singleplex_libs = SeqLib.find(:all, :conditions => ['id IN (?)', slib_ids])
      @singleplex_libs = SeqLib.find(:all, :conditions => ['seq_libs.id IN (?)', [347,348,349]])
      @singleplex_libs.reject!{|s_lib| s_lib.lib_samples[0].nil?}
#      @singleplex_libs.each_with_index do |s_lib, i|
#        @lib_samples[i] = LibSample.new(s_lib.lib_samples[0].attributes) 
#      end
      dropdowns
      render :action => 'debug'
    end
  end

  # PUT /seq_libs/1
  def update
    @seq_lib = FlowCell.find(params[:id])
    
    if params[:utype] == 'seq'
      fc_attrs = upd_for_sequencing(params)
      lane_errors = [0, '']
      success_msg = 'queued for sequencing'
    else
      fc_attrs = params[:seq_lib]
      lane_errors = validate_lane_nrs(params[:seq_lib][:existing_lane_attributes], 'update', params[:lane_count].to_i)
      success_msg = 'updated'
    end
    
    if lane_errors[0] > 0
      flash[:error] = "ERROR - #{lane_errors[1]}"
      dropdowns
      @seq_lib.existing_lane_attributes = params[:seq_lib][:existing_lane_attributes]
      render :action => 'edit'
      #render :action => 'debug'
      
    elsif @seq_lib.update_attributes(fc_attrs)
      FlowLane.upd_seq_key(@seq_lib)  if params[:utype] == 'seq'
      flash[:notice] = 'Flow cell was successfully ' + success_msg
      redirect_to(@seq_lib) 
      #render :action => 'debug'
      
    else
      flash[:error] = 'ERROR - Unable to update flow cell'
      dropdowns
      @seq_lib.existing_lane_attributes = params[:seq_lib][:existing_lane_attributes]
      render :action => "edit"
    end
  end

  # DELETE /seq_libs/1
  def destroy
    @seq_lib = SeqLib.find(params[:id])
    @seq_lib.destroy
    redirect_to mplex_libs_url
  end
  
protected
  def dropdowns
    @adapters     = Category.populate_dropdown_for_category('run_type')
    @adapters.reject! {|adapter| adapter.c_value[0,1] == 'S'}
    @enzymes      = Category.populate_dropdown_for_category('enzyme')
    @align_refs   = AlignmentRef.populate_dropdown
    @projects     = Category.populate_dropdown_for_category('project')
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('L')
    @quantitation= Category.populate_dropdown_for_category('quantitation')
  end
  
  def setup_dropdowns
    @owners    =  Researcher.populate_dropdown('incl_inactive')
    @adapters  = Category.populate_dropdown_for_category('run_type')
  end
  
  def define_lib_conditions(params)
    @where_select = []; @where_values = []
    
    if params[:seq_lib] 
      if !param_blank?(params[:seq_lib][:owner])
        @where_select.push('seq_libs.owner IN (?)')
        @where_values.push(params[:seq_lib][:owner])
      end
      if !param_blank?(params[:seq_lib][:runtype_adapter])
        @where_select.push('seq_libs.runtype_adapter = ?')
        @where_values.push(params[:seq_lib][:runtype_adapter])
      end
    end
    
    if params[:excl_used] && params[:excl_used] == 'Y'
      @where_select.push("seq_libs.lib_status <> 'F'")
    end
      
    date_fld = 'seq_libs.preparation_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params, date_fld)
    
    # Include control libraries, irrespective of other parameters entered
    if @where_select.length > 0
      @where_string = "seq_libs.lib_status = 'C' OR (" + @where_select.join(' AND ') + ")"
    else
      @where_string = "seq_libs.lib_status = 'C'"
    end
    
    return [@where_string] | @where_values
  end
  
end 