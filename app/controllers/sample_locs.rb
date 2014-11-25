class SampleLocsController < ApplicationController
  load_and_authorize_resource

  before_filter :dropdowns, :only => [:edit]

  # GET /sample_locs/1/edit
  def edit
    @sample_loc = SampleLoc.includes(:sample_storage_containers).find(params[:id])
    authorize! :edit, @sample_loc
    render :action => 'edit'
  end

  # PUT /sample_locs/1
  def update
    @sample_loc = SampleLoc.find(params[:id])
    authorize! :update, @sample_loc

    if @sample_loc.update_attributes(params[:sample_loc])
      flash[:notice] = 'Sample location was successfully updated.'
      redirect_to(@sample_loc) 
    else
      dropdowns
      flash[:error] = 'ERROR - Unable to update sample location'
      render :action => 'edit' 
    end
  end

protected
  def dropdowns
    @freezer_locations  = FreezerLocation.list_all_by_room
  end

end