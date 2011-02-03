class SeqMachinesController < ApplicationController
  load_and_authorize_resource

  # GET /seq_machines
  def index
    @seq_machines = SeqMachine.find_all_with_incidents
  end

  # GET /seq_machines/new
  def new
    @seq_machine = SeqMachine.new
  end

  # GET /seq_machines/1/edit
  def edit
    @seq_machine = SeqMachine.find_with_incidents(params[:id])
  end
  
  def show
    @seq_machine = SeqMachine.find_with_incidents(params[:id])
  end

  # POST /seq_machines
  def create
    @seq_machine = SeqMachine.new(params[:seq_machine])

    if @seq_machine.save
      flash[:notice] = 'SeqMachine was successfully created.'
      redirect_to(seq_machines_url)
    else
      render :action => "new" 
    end
  end

  # PUT /seq_machines/1
  def update
    @seq_machine = SeqMachine.find(params[:id])
    
    if @seq_machine.update_attributes(params[:seq_machine])
      flash[:notice] = 'SeqMachine was successfully updated.'
      redirect_to(seq_machines_url)
    else
      render :action => "edit" 
    end
  end

  # DELETE /seq_machines/1
  def destroy
    @seq_machine = SeqMachine.find(params[:id])
    @seq_machine.destroy
    redirect_to(seq_machines_url) 
  end

end
