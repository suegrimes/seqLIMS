class ConsentProtocolsController < ApplicationController
  load_and_authorize_resource

  # GET /consent_protocols
  def index
    @consent_protocols = ConsentProtocol.find_and_sort_all
  end

  # GET /consent_protocols/1
  def show
    @consent_protocol = ConsentProtocol.find(params[:id])
  end

  # GET /consent_protocols/new
  def new
    @consent_protocol = ConsentProtocol.new
  end

  # GET /consent_protocols/1/edit
  def edit
    @consent_protocol = ConsentProtocol.find(params[:id])
  end

  # POST /consent_protocols
  def create
    @consent_protocol = ConsentProtocol.new(params[:consent_protocol])

    if @consent_protocol.save
      flash[:notice] = 'ConsentProtocol was successfully created.'
      redirect_to(consent_protocols_url)
    else
      render :action => "new" 
    end
  end

  # PUT /consent_protocols/1
  def update
    @consent_protocol = ConsentProtocol.find(params[:id])

    if @consent_protocol.update_attributes(params[:consent_protocol])
      flash[:notice] = 'ConsentProtocol was successfully updated.'
      redirect_to(consent_protocols_url)
    else
      render :action => "edit" 
    end
  end

  # DELETE /consent_protocols/1
  def destroy
    @consent_protocol = ConsentProtocol.find(params[:id])
    @consent_protocol.destroy
    redirect_to(consent_protocols_url) 
  end
end
