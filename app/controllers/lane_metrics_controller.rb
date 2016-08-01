class LaneMetricsController < ApplicationController
  load_and_authorize_resource

  # GET /align_qcs/new
  def new
    dropdowns
  end

  # POST /align_qcs
  def create
    metrics_added = 0
    @flow_cell = FlowCell.includes(:flow_lanes => :lane_metric).find(params[:flow_cell][:id])
    
    flow_lane_metric = @flow_cell.flow_lanes.collect{|flow_lane| flow_lane.lane_metric}
    flow_lane_metric.reject!{|qc| qc.nil?}
    
    if flow_lane_metric && (flow_lane_metric.size == @flow_cell.flow_lanes.size)
      flash.now[:error] = "ERROR: All #{flow_lane_metric.size} QC rows already exist for run #{@flow_cell.sequencing_key} lanes"
    else
      metrics_added = LaneMetric.add_qc_for_flow_cell(@flow_cell.id)
    end

    if metrics_added == @flow_cell.flow_lanes.size
      flash[:notice] = "QC rows successfully added for #{metrics_added} lanes for run: #{@flow_cell.sequencing_key}"
      redirect_to flow_cell_qc_url(:id => @flow_cell.id)
      
    elsif metrics_added > 0
      flash[:notice] = "Some QC existed for this run: #{@flow_cell.sequencing_key}; #{alignqc_added} QC lanes added"
      redirect_to flow_cell_qc_url(:id => @flow_cell.id)
      
    else
      flash[:notice] = "Unable to add QC for: #{@flow_cell.sequencing_key} - validation error"
      dropdowns
      render :action => "new" 
    end
  end
  
  def edit
    @align_qc = AlignQc.find(params[:id])
    render :action => 'edit_ga2'
  end
  
  def update
    @align_qc = AlignQc.find(params[:id])
    
    if @align_qc.update_attributes(params[:align_qc])
      flash[:notice] = 'Alignment/QC was successfully updated.'
      redirect_to flow_cell_qc_url(:id => @align_qc.flow_lane.flow_cell_id)
    else
      flash.now[:error] = 'Error - Alignment/QC not updated'
      render :action => 'edit_ga2'
    end
  end

protected
  def dropdowns
    @seq_runs = FlowCell.find_sequencing_runs(SEQ_ORDER, "flowcell_status <> 'Q'")
  end

end

