class PublicationsController < ApplicationController
  ## cancan
  #load_and_authorize_resource

  # render index.rhtml
  def index
    @publications = Publication.find(:all)
  end

  # render new.rhtml
  def new
    @publication = Publication.new
    @flow_lanes = FlowLane.find(:all)
    @researchers = Researcher.find(:all)
  end

  def create
    @publication = Publication.new(params[:publication])
    
    if @publication.errors.empty?
      @publication.save
      flash[:notice] = "Publication successfully saved"
      redirect_to publications_url
    else
      flash.now[:notice] = "Error saving this publication - please try again"
      render :action => 'new'
    end
  end
  
  # render edit.html
  def edit 
    @publication = Publication.find(params[:id])
    @flow_lanes = FlowLane.find(:all)
    @researchers = Researcher.find(:all)
  end
  
  def update
    @publication = Publication.find(params[:id])
    authorize! :update, @publication
    
    params[:publication][:flow_cell_ids] ||= [] 
    @publication.flow_lanes = FlowLane.find(params[:publication][:flow_lane_ids])
    
    params[:publication][:researcher_ids] ||= []
    @publication.researchers = Researcher.find(params[:publication][:researcher_ids])
    
    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Publication has been updated"
      redirect_to publications_url
    else
      flash.now[:error] = "Error updating publication"
      @flow_lanes = FlowLane.find(:all)
      @researchers = Researcher.find(:all)
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
      @flow_cell = FlowCell.find_by_seq_run_nr(params[:run_numbers], :include => :flow_lanes) 
    end
    
    if @flow_cell.nil?
      render :nothing => true
    else
      render :partial => 'publication_runs', :locals => {:flow_cell => @flow_cell}
    end
  end
end

