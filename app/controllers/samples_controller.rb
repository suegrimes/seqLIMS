class SamplesController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new, :edit, :edit_by_barcode]
  
  #########################################################################################
  #        Methods to show, edit, update samples                                          #
  #########################################################################################
  def show
    @sample_is_new = (params[:new_sample] ||= false)
    @sample = Sample.find(params[:id], :include => :sample_characteristic )
  end
  
  # GET /samples/1/edit
  def edit
    @sample_is_new = (params[:new_sample] ||= false)
    @sample = Sample.find(params[:id], :include => [:sample_characteristic, :patient])
  end
  
  def edit_params 
    if request.post?
      btype = barcode_type(params[:barcode_key])
      case btype
        when 'S'
          redirect_to :action => :edit_by_barcode, :barcode_key => params[:barcode_key]
        when 'H'
          redirect_to :controller => :histologies, :action => :edit_by_barcode, :barcode_key => params[:barcode_key]
        when 'D', 'R', 'N', 'P'
          redirect_to :controller => :processed_samples, :action => :edit_by_barcode, :barcode_key => params[:barcode_key]      
        else
          flash[:notice] = 'Invalid barcode - please try again'
          redirect_to :action => :edit_params
      end
    end
  end
  
  def edit_by_barcode
    @sample = Sample.find_by_barcode_key(params[:barcode_key])
    if @sample
      if @sample.clinical_sample == 'no' 
        redirect_to :controller => :dissected_samples, :action => :edit, :id => @sample.id
      else
        render :action => :edit
      end
    else
      flash.now[:error] = 'No entry found for source barcode: ' + params[:barcode_key]
      render :action => :edit_params
    end
  end
  
  def update
    @sample = Sample.find(params[:id])
    
    if @sample.update_attributes(params[:sample])
      flash[:notice] = 'Sample was successfully updated'
      redirect_to(@sample)
    else
      flash[:error] = 'Error updating sample'
      dropdowns
      render :action => 'edit'
    end
  end
  
  # DELETE /samples/1
  def destroy
    @sample = Sample.find(params[:id])
    patient_id = @sample.patient_id
    @sample.destroy

    redirect_to :controller => :sample_queries, :action => 'list_samples_for_patient', :patient_id => patient_id
  end
  
  def testing
    @source_sample = Sample.find(params[:id]) 
    @new_barcode = Sample.next_dissection_barcode(@source_sample.id, @source_sample.barcode_key)
    render :action => 'debug'
  end

protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @sample_units       = category_filter(@category_dropdowns, 'sample unit')
    @vial_types         = category_filter(@category_dropdowns, 'vial type')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure') 
    @storage_locations  = StorageLocation.list_all_by_room
  end

end
