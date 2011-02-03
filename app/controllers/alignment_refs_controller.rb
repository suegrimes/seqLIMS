class AlignmentRefsController < ApplicationController
  load_and_authorize_resource

  # GET /alignment_refs
  def index
    @alignment_refs = AlignmentRef.find_and_sort_all
  end

  # GET /alignment_refs/1
  def show
    @alignment_ref = AlignmentRef.find(params[:id])
  end

  # GET /alignment_refs/new
  def new
    @alignment_ref = AlignmentRef.new
  end

  # GET /alignment_refs/1/edit
  def edit
    @alignment_ref = AlignmentRef.find(params[:id])
  end

  # POST /alignment_refs
  def create
    @alignment_ref = AlignmentRef.new(params[:alignment_ref])

    if @alignment_ref.save
      flash[:notice] = 'AlignmentRef was successfully created.'
      redirect_to(alignment_refs_url)
    else
      render :action => "new" 
    end
  end

  # PUT /alignment_refs/1
  def update
    @alignment_ref = AlignmentRef.find(params[:id])

    if @alignment_ref.update_attributes(params[:alignment_ref])
      flash[:notice] = 'AlignmentRef was successfully updated.'
      redirect_to(alignment_refs_url)
    else
      render :action => "edit" 
    end
  end

  # DELETE /alignment_refs/1
  def destroy
    @alignment_ref = AlignmentRef.find(params[:id])
    @alignment_ref.destroy
    redirect_to(alignment_refs_url) 
  end
end

