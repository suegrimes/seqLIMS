class FlowCellsController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new, :edit]
  before_filter :setup_dropdowns, :only => :setup_params
  before_filter :seq_dropdowns, :only => :show
  
  def setup_params
   @from_date = (Date.today - 3.months).beginning_of_month
   @to_date   =  Date.today
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
      @flow_cells = FlowCell.find_sequencing_runs
    end
  end
  
  # GET /flow_cells/1
  def show
    @flow_cell = FlowCell.find(params[:id], :include => {:flow_lanes => :seq_lib},
                               :order => 'flow_lanes.lane_nr')
  end
 
  def show_qc
    @flow_cell = FlowCell.find(params[:id], :include => :flow_lanes,
                               :order => 'flow_lanes.lane_nr')
  end
  
  def new
    @flow_cell       = FlowCell.new(:flowcell_date => Date.today)
    
    # Get sequencing libraries based on parameters entered
    @condition_array = define_lib_conditions(params)
    @seq_libs        = SeqLib.find(:all, :include => :mlib_samples, :conditions => @condition_array,
                                   :order => 'lib_status, lib_name')
                                   
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
    @flow_cell = FlowCell.find(params[:id], :include => {:flow_lanes => :seq_lib}, 
                               :order => 'flow_lanes.lane_nr')
    @partial_flowcell = (@flow_cell.flow_lanes.size < FlowCell::NR_LANES ? 'Y' : 'N')
  end

  # POST /flow_cells
  def create 
    params[:flow_cell].merge!(:flowcell_status => 'F')
    
    # Builds flow_lanes for all lanes (even blank lane#s).  Need to include blank
    # lanes so that all sequencing libraries show with appropriate lanes (or blank)
    # when error condition is encountered
    @flow_cell       = FlowCell.new(params[:flow_cell])
    
    lane_nrs = non_blank_lane_nrs(non_blank_lanes(params[:flow_lane]))  # Array of lane#s which are non-blank
    lanes_required  = (params[:partial_flowcell] == 'Y'? lane_nrs.size : FlowCell::NR_LANES)
      
    # Validation check to ensure lanes 1-8 entered, and no duplicate lanes
    lane_errors = validate_lane_nrs(params[:flow_lane], 'create', lanes_required)
    
    if param_blank?(params[:flow_cell][:nr_bases_read1])
      flash[:error] = "ERROR - Please enter number of bases, read 1"
      prepare_for_render_new(params)
      render :action => 'new'
      
    elsif lane_errors[0] > 0
      flash[:error] = "ERROR - #{lane_errors[1]}"
      prepare_for_render_new(params)
      render :action => 'new'
        
    else 
      @flow_cell.build_flow_lanes(params[:flow_lane])
      if @flow_cell.save
        SeqLib.upd_lib_status(@flow_cell, 'F') 
        flash[:notice] = 'Flow cell was successfully created'
        redirect_to(@flow_cell)
     
      else
        flash[:error] = 'ERROR - Unable to create flow cell'
        prepare_for_render_new(params)
        render :action => 'new'
      end
    end
  end

  # PUT /flow_cells/1
  def update
    @flow_cell = FlowCell.find(params[:id])
    
    if params[:utype] == 'seq'
      fc_attrs = upd_for_sequencing(params)
      lane_errors = [0, '']
      success_msg = 'queued for sequencing'
    else
      fc_attrs = params[:flow_cell]
      lane_errors = validate_lane_nrs(params[:flow_cell][:existing_lane_attributes], 'update', params[:lane_count].to_i)
      success_msg = 'updated'
    end
    
    if lane_errors[0] > 0
      flash[:error] = "ERROR - #{lane_errors[1]}"
      dropdowns
      @flow_cell.existing_lane_attributes = params[:flow_cell][:existing_lane_attributes]
      render :action => 'edit'
      #render :action => 'debug'
      
    elsif @flow_cell.update_attributes(fc_attrs)
      FlowLane.upd_seq_key(@flow_cell)  if params[:utype] == 'seq'
      flash[:notice] = 'Flow cell was successfully ' + success_msg
      redirect_to(@flow_cell) 
      #render :action => 'debug'
      
    else
      flash[:error] = 'ERROR - Unable to update flow cell'
      dropdowns
      @flow_cell.existing_lane_attributes = params[:flow_cell][:existing_lane_attributes]
      render :action => "edit"
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
  
  def auto_complete_for_sequencing_key
    @flow_cells = FlowCell.sequenced.find(:all, :conditions => ["sequencing_key LIKE ?", params[:search] + '%'])
    render :inline => "<%= auto_complete_result(@flow_cells, 'sequencing_key') %>"
  end
  
protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sequencing']])
    @cluster_kits       = category_filter(@category_dropdowns, 'cluster kit')
    @seq_kits           = category_filter(@category_dropdowns, 'sequencing kit')
    @adapters           = category_filter(@category_dropdowns, 'run_type')
    @enzymes            = category_filter(@category_dropdowns, 'enzyme')
    @align_refs         = AlignmentRef.populate_dropdown
  end
  
  def setup_dropdowns
    @owners    =  Researcher.populate_dropdown('incl_inactive')
  end
  
  def seq_dropdowns
    @sequencers       = SeqMachine.sequencers.find(:all)  
  end
  
  def prepare_for_render_new(params)
    dropdowns
    # Need to recreate seq_lib rows, using lanes[:seq_lib_id]
    @seq_libs = []
    @flow_lanes = []
    @partial_flowcell = params[:partial_flowcell]
    params[:flow_lane].each do |lane|
      @flow_lanes.push(FlowLane.new(lane))
      @seq_libs.push(SeqLib.find_by_id(lane[:seq_lib_id])) 
    end
  end
  
  def validate_lane_nrs(lanes, create_or_update, lanes_required = FlowCell::NR_LANES)
    errno = 0
    
    if create_or_update == 'create'    
      lanes_nb = non_blank_lanes(lanes)   
      lane_nrs = non_blank_lane_nrs(lanes_nb)
      
    else # create_or_update == update
      lanes_nb = non_blank_lanes(lanes) 
      errno = 4 if lanes_nb.size != lanes_required
      
      lane_nrs = non_blank_lane_nrs(lanes_nb)
      errno = 5 if lane_nrs.size != lanes_required
    end
    
    case errno
      when 4
        return [errno, "Lane number cannot be blank - cannot add or delete lib/lanes after flow cell creation"]
      when 5
        return [errno, "Lane number must be integer - cannot assign a sequencing library to multiple lanes, after flow cell creation"]
      else
        return check_for_lane_errors(lane_nrs.collect{|lane| lane.to_i}, lanes_required)
    end  
  end
  
  def check_for_lane_errors(lane_nrs, lanes_required)
    nr_entered_lanes = lane_nrs.size
    nr_unique_lanes  = lane_nrs.uniq.size
    
    if nr_entered_lanes != lanes_required
      errno  = 1
      errmsg = "Must have exactly #{lanes_required} lanes - #{nr_entered_lanes} were assigned"
      
    elsif nr_unique_lanes != lanes_required
      errno  = 2
      errmsg = "One or more lane numbers assigned multiple times"
    
    elsif (lane_nrs.min < 1 || lane_nrs.max > FlowCell::NR_LANES)
      errno = 3
      errmsg = "Lane numbers must be integers between 1 and #{FlowCell::NR_LANES}"
      
    else
      errno = 0
      errmsg = ''
    end
    
    return [errno, errmsg]
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
      nb_lanes.collect{|lane| lane[:lane_nr].split(',')}.flatten
    else  # Hash
      nb_lanes.collect{|lane_id, lane_attrs| lane_attrs[:lane_nr].split(',')}.flatten
    end
  end
  
  def define_lib_conditions(params)
    @where_select = []; @where_values = []
    
    if params[:seq_lib] && !param_blank?(params[:seq_lib][:owner])
      @where_select.push('seq_libs.owner IN (?)')
      @where_values.push(params[:seq_lib][:owner])
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
  
  def upd_for_sequencing(params)
    seq_date_ymd    = params[:flow_cell][:sequencing_date].gsub(/-/, '')
      
    # create sequencing key (concatenate date, machine name, sequential#)  
    seq_runnr   = SeqMachine.find_and_incr_run_nr
    seq_machine = SeqMachine.find(params[:seq_machine][:id])
    
    # flow cell status updated to 'R' to signify ready for sequencing
    params[:flow_cell].merge!(:sequencing_key  => format_seq_key(seq_date_ymd, seq_machine.machine_name, seq_runnr),
                              :seq_machine_id  => seq_machine.id,
                              :sequencer_type  => seq_machine.machine_type[0,1],
                              :seq_run_nr      => seq_runnr,
                              :flowcell_status => 'R')
    return params[:flow_cell]
  end
  
  def format_seq_key(seq_date, machine_name, run_nr)
    return "%s_%s_%04d" % [seq_date.to_s, machine_name, run_nr]
  end
  
end 