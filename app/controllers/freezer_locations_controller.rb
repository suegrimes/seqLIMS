class FreezerLocationsController < ApplicationController
  load_and_authorize_resource

  # GET /freezer_locations
  def index
    @freezer_locations = FreezerLocation.list_all_by_room
  end

  # GET /freezer_locations/1
  def show
    @freezer_location = FreezerLocation.find(params[:id])
  end

  # GET /freezer_locations/new
  def new
    @freezer_location = FreezerLocation.new
  end

  # GET /freezer_locations/1/edit
  def edit
    @freezer_location = FreezerLocation.find(params[:id])
  end

  # POST /freezer_locations
  def create
    @freezer_location = FreezerLocation.new(params[:freezer_location])

    if @freezer_location.save
      flash[:notice] = 'FreezerLocation was successfully created.'
      redirect_to(@freezer_location)
    else
      render :action => "new" 
    end
  end

  # PUT /freezer_locations/1
  def update
    @freezer_location = FreezerLocation.find(params[:id])

    if @freezer_location.update_attributes(params[:freezer_location])
      flash[:notice] = 'FreezerLocation was successfully updated.'
      redirect_to(@freezer_location)
    else
      render :action => "edit" 
    end
  end

  # DELETE /freezer_locations/1
  def destroy
    @freezer_location = FreezerLocation.find(params[:id])
    @freezer_location.destroy
    redirect_to(freezer_locations_url) 
  end
end
