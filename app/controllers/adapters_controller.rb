class AdaptersController < ApplicationController
  load_and_authorize_resource
  
  # GET /adapters
  def index
    @adapters = Adapter.all
  end

  # GET /adapters/1
  def show
    @adapter = Adapter.preload(:index_tags).find(params[:id])
    @adapter.index_tags.sort_by! {|itag| itag.index_read}
    #render 'debug'
  end

  # GET /adapters/1/edit
  def edit
    @adapter = Adapter.includes(:index_tags).find(params[:id])
  end

  # PUT /adapters/1
  def update
    
    @adapter = Adapter.find(params[:id])
    if @adapter.update_attributes(params[:adapter])
      
      # Delete any adapter value records which were removed/deleted from edit screen
      params[:adapter][:index_tags_attributes].each do |ikey, iattrs|
        IndexTag.destroy(iattrs[:id]) if iattrs[:tag_sequence].blank?
      end
      
      flash[:notice] = "Successfully updated adapter and multiplex indices"
      redirect_to(@adapter)
    else
      render :action => 'edit'
    end
    
  end

  # DELETE /adapters/1
  def destroy
    @adapter = Adapter.find(params[:id])
    @adapter.destroy

    redirect_to(adapters_url)
    end
end
