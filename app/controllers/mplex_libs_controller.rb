class MplexLibsController < ApplicationController
  #load_and_authorize_resource :class => 'SeqLib'  
  
  before_filter :dropdowns, :only => [:new, :edit]
  before_filter :setup_dropdowns, :only => :setup_params

  def setup_params
   @from_date = (Date.today - 3.months).beginning_of_month
   @to_date   =  Date.today
   @date_range = DateRange.new(@from_date, @to_date)
   @seq_lib   = SeqLib.new(:owner => (current_user.researcher ? current_user.researcher.researcher_name : nil),
                           :runtype_adapter => 'M_PE')
  end
  
  def new
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @seq_lib   = SeqLib.new(:library_type => 'M',
                            :owner => @requester,
                            :preparation_date => Date.today,
                            :runtype_adapter => params[:seq_lib][:runtype_adapter],
                            :alignment_ref_id => AlignmentRef.default_id)
    
    # Get sequencing libraries based on parameters entered
    @condition_array = define_lib_conditions(params)
    @singleplex_libs = SeqLib.includes(:mlib_samples, {:lib_samples => :processed_sample}).where(sql_where(@condition_array))
                             .order('barcode_key, lib_name').all
    if params[:excl_used] && params[:excl_used] == 'Y'
      @singleplex_libs.reject!{|s_lib| !s_lib.mlib_samples.empty?} #Exclude if already included in a multiplex library
    end
                                   
    # Populate lib_samples based on data in each sequencing library
    @lib_samples = []    
    @singleplex_libs.each_with_index do |s_lib, i|
      @lib_samples[i] = LibSample.new(:processed_sample_id => s_lib.lib_samples[0].processed_sample_id,
                                      :sample_name         => s_lib.lib_samples[0].sample_name,
                                      :source_DNA          => s_lib.lib_samples[0].source_DNA,
                                      :runtype_adapter     => s_lib.lib_samples[0].runtype_adapter,
                                      :index_tag           => s_lib.lib_samples[0].index_tag,
                                      :enzyme_code         => s_lib.lib_samples[0].enzyme_code,
                                      :notes               => s_lib.lib_samples[0].notes)
    end     
    @checked = false
    render :action => 'new'
    #render :action => 'debug'
  end
  
  # GET /mplex_libs/1/edit
  def edit
    @seq_lib = SeqLib.includes(:lib_samples).find(params[:id])
  end

  # POST /mplex_libs
  def create
    @seq_lib       = SeqLib.new(params[:seq_lib])
    @seq_lib[:library_type] = 'M'
    @seq_lib[:alignment_ref] = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])
    
    #slib_params = array of arrays [][id, notes]; slib_ids = array of ids [id1, id2, ..]
    slib_params = params[:lib_samples].collect{|lsample| [lsample[:splex_lib_id].to_i, lsample[:notes]]}
    slib_params.delete_if{|sparam| sparam[0] == 0}
    slib_ids_checked = slib_params.collect{|sparam| sparam[0]}
    slib_ids_all = params[:lib_id].to_a

    splex_libs = SeqLib.includes(:lib_samples).where('seq_libs.id in (?)', slib_ids_checked).all
    error_found = false
    slib_tags = splex_libs.collect{|slib| slib.lib_samples[0].index_tag } 
    slib_pools = splex_libs.collect{|slib| [slib.pool_id, slib.oligo_pool]}
    if slib_pools.uniq.size > 1 
      @seq_lib[:oligo_pool] =  'Multiple'
    elsif slib_pools.uniq.size == 1
      @seq_lib[:pool_id] = slib_pools[0][0]
      @seq_lib[:oligo_pool] = slib_pools[0][1]
    end
    
    if splex_libs.size > 1 && slib_tags.size == slib_tags.uniq.size # More than 1 library selected; All index tags are unique, 
      splex_libs.each do |s_lib|
        slib_notes = slib_params.assoc(s_lib.id)[1] #Find params array entry for this seq_lib.id, and extract notes field 
        @seq_lib.lib_samples.build(:processed_sample_id => s_lib.lib_samples[0].processed_sample_id,
                                   :sample_name         => s_lib.lib_samples[0].sample_name,
                                   :source_DNA          => s_lib.lib_samples[0].source_DNA,
                                   :runtype_adapter     => s_lib.lib_samples[0].runtype_adapter,
                                   :index_tag           => s_lib.lib_samples[0].index_tag,
                                   :enzyme_code         => s_lib.lib_samples[0].enzyme_code,
                                   :splex_lib_id        => s_lib.id,
                                   :splex_lib_barcode   => s_lib.barcode_key,
                                   :notes               => slib_notes)
      end  
      if !@seq_lib.save
        error_found = true  # Validation or other error when saving to database
        flash.now[:error] = 'ERROR - Unable to create multiplex library'
      end
      
    elsif splex_libs.size < 2   #Only one sequencing library selected     
      flash.now[:error] = 'ERROR - Only one sequencing library selected for multiplexing'
      error_found = true 
      
    elsif slib_tags.size > slib_tags.uniq.size  # One or more duplicate tags
      flash.now[:error] = 'ERROR - Duplicate index tags entered for this multiplex library'
      error_found = true
    end
     
    if error_found
      @singleplex_libs = SeqLib.includes(:lib_samples => :processed_sample).where('seq_libs.id IN (?)', slib_ids_all)
                               .order('barcode_key, lib_name')
      @lib_samples = []
      @singleplex_libs.each_with_index do |slib, i|
        @lib_samples[i] = LibSample.new(slib.lib_samples[0].attributes)
        if slib_ids_checked.include?(slib.id)
          @lib_samples[i][:splex_lib_id] = slib.id 
          @lib_samples[i][:notes] = slib_params.assoc(slib.id)[1]
        end
      end
      dropdowns
      render :action => 'new'
    else
     flash[:notice] = 'Multiplex library successfully created'
     redirect_to(@seq_lib)
    end
    #render :action => 'debug'
  end

  # PUT /mplex_libs/1
  def update
    @seq_lib = SeqLib.find(params[:id])
    alignment_key = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])
    params[:seq_lib].merge!(:alignment_ref => alignment_key)
     
    if @seq_lib.update_attributes(params[:seq_lib])
      SeqLib.upd_mplex_fields(@seq_lib)
      if @seq_lib.on_flow_lane?
        FlowLane.upd_lib_lanes(@seq_lib)
      end
      flash[:notice] = 'Multiplex library was successfully updated'
      redirect_to(@seq_lib) 
      
    else
      flash[:error] = 'ERROR - Unable to update sequencing library'
      dropdowns
      render :action => "edit"
    end
  end

  # DELETE /mplex_libs/1
  def destroy
    @seq_lib = SeqLib.find(params[:id])
    @seq_lib.destroy
    flash[:notice] = 'Multiplex sequencing library successfully deleted'
    redirect_to seq_libs_url
  end
  
protected
  def dropdowns
    @enzymes      = Category.populate_dropdown_for_category('enzyme')
    @align_refs   = AlignmentRef.populate_dropdown
    @projects     = Category.populate_dropdown_for_category('project')
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('L')
    @quantitation= Category.populate_dropdown_for_category('quantitation')
  end
  
  def setup_dropdowns
    @owners    =  Researcher.populate_dropdown('incl_inactive')
    @mplex_adapters  = IndexTag.mplex_adapters
  end
  
  def define_lib_conditions(params)
    @where_select = ["seq_libs.library_type = 'S'"] 
    @where_values = []
    
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
    
    if !param_blank?(params[:barcode_from]) || !param_blank?(params[:barcode_to])
      @where_select.push("seq_libs.barcode_key LIKE 'L%'")
      barcode_from = (param_blank?(params[:barcode_from]) ? nil : params[:barcode_from].to_i)
      barcode_to   = (param_blank?(params[:barcode_to])? nil : params[:barcode_to].to_i)
      @where_select, @where_values = sql_conditions_for_range(@where_select, @where_values, barcode_from, barcode_to,
                                                              "CAST(SUBSTRING(seq_libs.barcode_key,2) AS UNSIGNED)")
    end
                                     
    if params[:excl_used] && params[:excl_used] == 'Y'
      @where_select.push("seq_libs.lib_status <> 'F'")
    end
      
    date_fld = 'seq_libs.preparation_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params, date_fld)
    
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end
  
end 