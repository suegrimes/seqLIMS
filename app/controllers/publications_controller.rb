class PublicationsController < ApplicationController
  ## cancan
  #load_and_authorize_resource
  
  def show
    @publication = Publication.includes(:flow_lanes).order('flow_lanes.sequencing_key, flow_lanes.lane_nr').find(params[:id])
  end

  # render index.rhtml
  def index
    @publications = Publication.order('publications.date_published DESC').all
  end

  # render new.rhtml
  def new
    @publication = Publication.new
    dropdowns
  end

  def create
    @publication = Publication.new(params[:publication])
    
    if @publication.errors.empty?
      @publication.save
      flash[:notice] = "Publication successfully saved"
      redirect_to @publication
    else
      flash.now[:notice] = "Error saving this publication - please try again"
      @researchers = Researcher.all
      @checked_lane_ids = params[:publication][:flow_lane_ids].collect{|str| str.to_i} if params[:publication][:flow_lane_ids]
      flow_lanes = FlowLane.find_all_by_id(@checked_lane_ids) if @checked_lane_ids
      @flow_cells = FlowCell.find_all_by_id(flow_lanes.map(&:flow_cell_id).uniq) if flow_lanes
      render :action => 'new'
    end
  end
  
  # render edit.html
  def edit 
    @publication = Publication.find(params[:id])
    dropdowns
  end
  
  def update
    @publication = Publication.find(params[:id])
    authorize! :update, @publication
    
    params[:publication][:flow_lane_ids] ||= []
    params[:publication][:flow_lane_ids].reject!{|id| id.blank? || id == '0'}
    @publication.flow_lanes = FlowLane.find(params[:publication][:flow_lane_ids])
    
    params[:publication][:researcher_ids] ||= []
    @publication.researchers = Researcher.find(params[:publication][:researcher_ids])
    
    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Publication has been updated"
      redirect_to @publication
    else
      flash.now[:error] = "Error updating publication"
      @researchers = Researcher.all
      render :action => 'edit'
    end    
  end
  
  # DELETE /publications/1
  def destroy
    @publication = Publication.find(params[:id])
    authorize! :destroy, @publication      
    @publication.destroy
    redirect_to publications_url 
  end
  
  def populate_lanes
    if params[:run_numbers]
      @runnr_list = params[:run_numbers].split(',')
      @flow_cells = FlowCell.find_all_by_seq_run_nr(@runnr_list, :include => :flow_lanes,
                                                :order => "flow_cells.seq_run_nr, flow_lanes.lane_nr") 
    end

    respond_to {|format| format.js }
  end
  
  def dropdowns
    @researchers = Researcher.order('researchers.active_inactive, researchers.researcher_name').all
  end
end
