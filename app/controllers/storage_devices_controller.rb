class StorageDevicesController < ApplicationController
  load_and_authorize_resource
  
  def index
    @storage_devices = StorageDevice.find(:all, :order => :device_name)
  end

  def show
    @storage_device = StorageDevice.find(params[:id])
  end

  def new
    @storage_device = StorageDevice.new
  end

  def edit
    @storage_device = StorageDevice.find(params[:id])
  end

  def create
    @storage_device = StorageDevice.new(params[:storage_device])

    if @storage_device.save
      flash[:notice] = 'Storage device was successfully created.'
      redirect_to(@storage_device)
    else
      flash.now[:error] = 'Error saving storage device'
      render :action => "new"
    end
  end

  def update
    @storage_device = StorageDevice.find(params[:id])

    if @storage_device.update_attributes(params[:storage_device])
       flash[:notice] = 'Storage device was successfully updated.'
       redirect_to(@storage_device)
    else
       flash.now[:error] = 'Error updating storage device'
       render :action => "edit"
    end
  end

  def destroy
    @storage_device = StorageDevice.find(params[:id])
    @storage_device.destroy
    redirect_to(storage_devices_url)
  end
  
end
