class ProtocolsController < ApplicationController
  def query_params
    if request.post?
      case params[:protocol_type]
        when 'Consent'
          redirect_to consent_protocols_path
        when 'Extraction'
          redirect_to :action => :index, :type => 'E'
        when 'Library Prep'
          redirect_to :action => :index, :type => 'L'
      end
    else
      @protocol_types = ['Consent', 'Extraction', 'Library Prep']
    end
  end
  
  # GET /protocols
  def index
    params[:type] ||= 'E'
    @protocols = Protocol.find_for_protocol_type(params[:type])
  end

  # GET /protocols/1
  def show
    @protocol = Protocol.find(params[:id])
  end

  # GET /protocols/new
  def new
    @protocol = Protocol.new(:protocol_type => params[:protocol_type])
  end

  # GET /protocols/1/edit
  def edit
    @protocol = Protocol.find(params[:id])
  end

  # POST /protocols
  def create
    @protocol = Protocol.new(params[:protocol])

    if @protocol.save
      flash[:notice] = 'Protocol was successfully created.'
      redirect_to(@protocol)
    else
      render :action => "new"
    end
  end

  # PUT /protocols/1
  def update
    @protocol = Protocol.find(params[:id])

    if @protocol.update_attributes(params[:protocol])
      flash[:notice] = 'Protocol was successfully updated.'
      redirect_to(@protocol)
    else
      render :action => "edit"
    end
  end

  # DELETE /protocols/1
  def destroy
    @protocol = Protocol.find(params[:id])
    @protocol.destroy

   redirect_to(protocols_url)
  end
end
