class StorageLocationsController < ApplicationController
  load_and_authorize_resource

  # GET /storage_locations
  def index
    @storage_locations = StorageLocation.list_all_by_room
  end

  # GET /storage_locations/1
  def show
    @storage_location = StorageLocation.find(params[:id])
  end

  # GET /storage_locations/new
  def new
    @storage_location = StorageLocation.new
  end

  # GET /storage_locations/1/edit
  def edit
    @storage_location = StorageLocation.find(params[:id])
  end

  # POST /storage_locations
  def create
    @storage_location = StorageLocation.new(params[:storage_location])

    if @storage_location.save
      flash[:notice] = 'StorageLocation was successfully created.'
      redirect_to(@storage_location)
    else
      render :action => "new" 
    end
  end

  # PUT /storage_locations/1
  def update
    @storage_location = StorageLocation.find(params[:id])

    if @storage_location.update_attributes(params[:storage_location])
      flash[:notice] = 'StorageLocation was successfully updated.'
      redirect_to(@storage_location)
    else
      render :action => "edit" 
    end
  end

  # DELETE /storage_locations/1
  def destroy
    @storage_location = StorageLocation.find(params[:id])
    @storage_location.destroy
    redirect_to(storage_locations_url) 
  end
end
