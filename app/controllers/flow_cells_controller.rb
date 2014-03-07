class FlowCellsController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new, :edit]
  before_filter :setup_dropdowns, :only => :setup_params
  before_filter :seq_dropdowns, :only => :show
  
  autocomplete :flow_cells, :sequencing_key
  
  def setup_params
    @from_date = (Date.today - 3.months).beginning_of_month
    @to_date   =  Date.today
    @date_range = DateRange.new(@from_date, @to_date)
    @seq_lib   = SeqLib.new(:owner => (current_user.researcher ? current_user.researcher.researcher_name : nil))
  end
  
  # GET /flow_cells
  def index
    params[:rpt_type] ||= 'list'
    if params[:rpt_type] == 'seq'
      @hdr = 'Flow Cells for Sequencing'
      @flow_cells = FlowCell.find_flowcells_for_sequencing 
    else
      @hdr = 'Sequencing Runs'
      @flow_cells = FlowCell.find_sequencing_runs(SEQ_ORDER)
    end
  end
  
  # GET /flow_cells/1
  def show
    @flow_cell = FlowCell.includes(:flow_lanes => :seq_lib).order('flow_lanes.lane_nr').find(params[:id])
  end
 
  def show_qc
    @flow_cell = FlowCell.includes(:flow_lanes).order('flow_lanes.lane_nr').find(params[:id])
  end
  
  def show_publications
    @flow_cell    = FlowCell.find(params[:id])
    @publications = Publication.includes(:flow_lanes).where('flow_lanes.flow_cell_id = ?', params[:id])
                               .order('publications.date_published DESC, flow_lanes.lane_nr').all
  end
  
  def new
    @flow_cell       = FlowCell.new(:flowcell_date => Date.today)
    
    # Get sequencing libraries based on parameters entered
    @condition_array = define_lib_conditions(params)
    @seq_libs        = SeqLib.includes(:mlib_samples).where(sql_where(@condition_array)).order('lib_status, lib_name')
                                   
    # Exclude sequencing libraries which have been included in one or more multiplex libraries
    if params[:excl_used] && params[:excl_used] == 'Y'  
      @seq_libs.reject!{|seq_lib| !seq_lib.mlib_samples.empty?}
    end
    
    # Populate flow lanes for each sequencing library
    @flow_lanes = []
    @seq_libs.each_with_index do |lib, i|
      @flow_lanes[i] = FlowLane.new(:lane_nr    => lib.control_lane_nr,
                                    :lib_conc   => lib.lib_conc_requested,
                                    :seq_lib_id => lib.id)
    end     
    
    render :action => 'new'
  end
  
  # GET /flow_cells/1/edit
  def edit
    @flow_cell = FlowCell.includes(:flow_lanes => :seq_lib).order('flow_lanes.lane_nr').find(params[:id])
    @partial_flowcell = (@flow_cell.flow_lanes.size < FlowCell::NR_LANES[@flow_cell.machine_type.to_sym] ? 'Y' : 'N')
  end

  # POST /flow_cells
  def create 
    params[:flow_cell].merge!(:flowcell_status => 'F')
    
    # Builds flow_lanes for all lanes (even blank lane#s).  Need to include blank
    # lanes so that all sequencing libraries show with appropriate lanes (or blank)
    # when error condition is encountered
    @flow_cell  = FlowCell.new(params[:flow_cell]) 
    lane_params = params[:flow_lane]
    
    lane_nrs = non_blank_lane_nrs(non_blank_lanes(lane_params))  # Array of lane#s which are non-blank
    machine_type = (param_blank?(params[:flow_cell][:machine_type]) ? FlowCell::DEFAULT_MACHINE_TYPE : params[:flow_cell][:machine_type])
    max_lane_nr = FlowCell::NR_LANES[machine_type.to_sym]
    lanes_required  = (params[:partial_flowcell] == 'Y'? lane_nrs.size : max_lane_nr)
         
    # Validation check to ensure lanes 1-8 entered, and no duplicate lanes
    lane_errors = validate_lane_nrs(lane_params, 'create', lanes_required, max_lane_nr)
    
    if lane_errors[0] > 0
      flash[:error] = "ERROR - #{lane_errors[1]}"
      prepare_for_render_new(params)
      render :action => 'new'
           
    elsif @flow_cell.valid?
      @flow_cell.build_flow_lanes(lane_params)
      if @flow_cell.save
        SeqLib.upd_lib_status(@flow_cell, 'F') #Update seq_lib status for all libs on this flowcell
        flash[:notice] = 'Flow cell was successfully created'
        redirect_to(@flow_cell)
      else
        flash[:error] = 'ERROR - Unable to create flow cell'  #Shouldn't get here (all errors should be trapped prior to this)
        prepare_for_render_new(params)
        render :action => 'new'
      end
     
    else
      flash[:error] = 'ERROR - Flow cell validation failed, check required fields'
      prepare_for_render_new(params)
      render :action => 'new'
    end
  end

  # PUT /flow_cells/1
  def update
    @flow_cell = FlowCell.find(params[:id])
    fc_attrs = params[:flow_cell]
    machine_type = @flow_cell.machine_type
    max_lane_nr = FlowCell::NR_LANES[machine_type.to_sym]
    lanes_required  = (params[:partial_flowcell] == 'Y'? params[:lane_count].to_i : max_lane_nr)
    
    # Create copy of params, since need to delete blank lanes during validation, but want all lanes available for render :new, if error
    lane_params = params[:flow_cell][:existing_lane_attributes]  
    lane_errors = validate_lane_nrs(lane_params, 'update', lanes_required, max_lane_nr)
    
    if lane_errors[0] > 0
      flash[:error] = "ERROR - #{lane_errors[1]}"     
      dropdowns
      @flow_cell[:existing_lane_attributes] = params[:flow_cell][:existing_lane_attributes]
      render :action => 'edit'
      
    elsif @flow_cell.update_attributes(fc_attrs)
      flash[:notice] = 'Flow cell was successfully updated'
      redirect_to(@flow_cell) 
      
    else
      flash[:error] = 'ERROR - Unable to update flow cell'
      dropdowns
      @flow_cell[:existing_lane_attributes] = params[:flow_cell][:existing_lane_attributes]
      render :action => 'edit'
    end
  end
  
  def upd_for_sequencing
    @flow_cell = FlowCell.find(params[:id])
    fc_attrs = attrs_for_sequencing(params)
    
    if fc_attrs[:machine_type] != @flow_cell.machine_type  # Sequencing machine selected is not same type as specified on flow cell
      flash[:error] = "ERROR - Sequencing machine selected is not same type as flow cell"
      redirect_to(@flow_cell)
      
    elsif @flow_cell.update_attributes(fc_attrs)
      FlowLane.upd_seq_key(@flow_cell)
      flash[:notice] = 'Flow cell was successfully queued for sequencing'
      redirect_to(@flow_cell) 
      
    else
      flash[:error] = 'ERROR - Unable to update flow cell'
      redirect_to(@flow_cell)
    end 
  end

  # DELETE /flow_cells/1
  def destroy
    # to delete flow_cell, need to first delete associated lib_samples
    # make this an admin only function in production
    @flow_cell = FlowCell.find(params[:id])
    @flow_cell.destroy
    redirect_to flow_cells_url(:rpt_type => 'seq') 
  end
  
  #def auto_complete_for_sequencing_key
  def autocomplete_flow_cells_sequencing_key
    @flow_cells = FlowCell.sequenced.where('sequencing_key LIKE ?', params[:term] + '%').all
    #render :inline => "<%= auto_complete_result(@flow_cells, 'sequencing_key') %>"
    list = @flow_cells.map {|fc| Hash[ id: fc.id, label: fc.sequencing_key, name: fc.sequencing_key]}
    render json: list
  end
  
protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sequencing']])
    @cluster_kits       = category_filter(@category_dropdowns, 'cluster kit')
    @seq_kits           = category_filter(@category_dropdowns, 'sequencing kit')
    @projects           = category_filter(@category_dropdowns, 'project')
    @oligo_pools        = Pool.populate_dropdown('flowcell')
    @enzymes            = category_filter(@category_dropdowns, 'enzyme')
    @align_refs         = AlignmentRef.populate_dropdown
  end
  
  def setup_dropdowns
    @owners    =  Researcher.populate_dropdown('incl_inactive')
  end
  
  def seq_dropdowns
    @sequencers_by_bldg = SeqMachine.populate_dropdown_grouped
  end
  
  def prepare_for_render_new(params)
    dropdowns
    # Need to recreate seq_lib rows, using lanes[:seq_lib_id]
    @seq_libs = []; @flow_lanes = [];
    @partial_flowcell = params[:partial_flowcell]
    
    params[:flow_lane].each do |lane|
      @flow_lanes.push(FlowLane.new(lane))
      @seq_libs.push(SeqLib.find(lane[:seq_lib_id]))
    end
  end
  
  def validate_lane_nrs(lanes, upd_method, lanes_required, max_lane_nr = nil)
    errno = 0
    max_lane_nr ||= FlowCell::NR_LANES[FlowCell::DEFAULT_MACHINE_TYPE.to_sym]
        
    lanes_nb = non_blank_lanes(lanes)   
    lane_nrs = non_blank_lane_nrs(lanes_nb)
    nr_entered_lanes = lane_nrs.size
    nr_unique_lanes  = lane_nrs.uniq.size
      
    if upd_method == 'update'
      errno = case
        when lanes_nb.size != lanes_required    then 5
        when nr_entered_lanes != lanes_required then 6
        when (lane_nrs.min < 1 || lane_nrs.max > max_lane_nr) then (max_lane_nr == 1 ? 3 : 4)
        else 0
      end
    end
    
    if upd_method == 'create'
      errno = case
        when nr_entered_lanes != lanes_required then 1
        when nr_unique_lanes != lanes_required  then 2
        when (lane_nrs.min < 1 || lane_nrs.max > max_lane_nr) then (max_lane_nr == 1 ? 3 : 4)
        else 0
      end
    end
    
    case errno
      when 0 then return [errno, ""]
      when 1 then return [errno, "Must have exactly #{lanes_required} lanes for this machine type - #{nr_entered_lanes} were assigned"]
      when 2 then return [errno, "One or more lane numbers assigned multiple times"]
      when 3 then return [errno, "Lane number must be 1"]
      when 4 then return [errno, "Lane numbers must be integers between 1 and #{max_lane_nr}"]
      when 5 then return [errno, "Lane number cannot be blank - cannot add or delete lib/lanes after flow cell creation"]
      when 6 then return [errno, "Lane number must be integer - cannot assign a sequencing library to multiple lanes, after flow cell creation"]
    end
  end
  
  def non_blank_lanes(lanes)
    if lanes.is_a? Array
      lanes.reject{|lane| lane[:lane_nr].blank?} 
    else  #Hash
      lanes.reject{|lane_id, lane_attrs| lane_attrs[:lane_nr].blank?}
    end
  end
  
  def non_blank_lane_nrs(nb_lanes)
    if nb_lanes.is_a? Array
      lane_nrs = nb_lanes.collect{|lane| lane[:lane_nr].to_s.split(',')}.flatten
    else  # Hash
      lane_nrs = nb_lanes.collect{|lane_id, lane_attrs| lane_attrs[:lane_nr].to_s.split(',')}.flatten
    end
    return lane_nrs.collect{|lane| lane.to_i}
  end
  
  def define_lib_conditions(params)
    @where_select = []; @where_values = []
    
    if params[:seq_lib] && !param_blank?(params[:seq_lib][:owner])
      @where_select.push('seq_libs.owner IN (?)')
      @where_values.push(params[:seq_lib][:owner])
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
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:date_range], date_fld)
    
    # Include control libraries, irrespective of other parameters entered
    if @where_select.length > 0
      @where_string = "seq_libs.lib_status = 'C' OR (" + @where_select.join(' AND ') + ")"
    else
      @where_string = "seq_libs.lib_status = 'C'"
    end
    
    return [@where_string] | @where_values
  end
  
  def attrs_for_sequencing(params)
    seq_date_ymd    = params[:flow_cell][:sequencing_date].gsub(/-/, '')
      
    # create sequencing key (concatenate date, machine name, sequential#)  
    seq_runnr   = SeqMachine.find_and_incr_run_nr
    seq_machine = SeqMachine.find(params[:seq_machine][:id])
    
    # flow cell status updated to 'R' to signify ready for sequencing
    params[:flow_cell].merge!(:sequencing_key  => format_seq_key(seq_date_ymd, seq_machine.machine_name, seq_runnr),
                              :seq_machine_id  => seq_machine.id,
                              :machine_type    => seq_machine.machine_type,
                              :seq_run_nr      => seq_runnr,
                              :flowcell_status => 'R')
    return params[:flow_cell]
  end
  
  def format_seq_key(seq_date, machine_name, run_nr)
    return "%s_%s_%04d" % [seq_date.to_s, machine_name, run_nr]
  end
  
end 