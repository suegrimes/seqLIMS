class AlignQcsController < ApplicationController
  load_and_authorize_resource

  # GET /align_qcs/new
  def new
    dropdowns
  end

  # POST /align_qcs
  def create
    alignqc_added = 0
    @flow_cell = FlowCell.find(params[:flow_cell][:id], :include => {:flow_lanes => :align_qc})
    
    flow_cell_align_qc = @flow_cell.flow_lanes.collect{|flow_lane| flow_lane.align_qc}
    flow_cell_align_qc.reject!{|qc| qc.nil?}
    
    if flow_cell_align_qc && (flow_cell_align_qc.size == @flow_cell.flow_lanes.size)
      flash.now[:error] = "ERROR: All #{flow_cell_align_qc.size} QC rows already exist for run #{@flow_cell.sequencing_key} lanes"
    else
      alignqc_added = AlignQc.add_qc_for_flow_cell(@flow_cell.id)
    end

    if alignqc_added == @flow_cell.flow_lanes.size
      flash[:notice] = "QC rows successfully added for #{alignqc_added} lanes for run: #{@flow_cell.sequencing_key}"
      redirect_to flow_cell_qc_url(:id => @flow_cell.id)
      
    elsif alignqc_added > 0
      flash[:notice] = "Some QC existed for this run: #{@flow_cell.sequencing_key}; #{alignqc_added} QC lanes added"
      redirect_to flow_cell_qc_url(:id => @flow_cell.id)
      
    else
      #redirect_to flow_cell_qc_url(:id => @flow_cell.id)
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
    @seq_runs = FlowCell.find_sequencing_runs("flowcell_status <> 'Q'")
  end

end

