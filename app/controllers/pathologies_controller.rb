class PathologiesController < ApplicationController
#load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new, :edit]
  
  def new_params
    authorize! :create, Pathology
    
    @to_date = Date.today
    render :action => 'new_params'
  end
  
  def new
    params[:add_new] ||= 'no'
    error_found = false  
    
    if !param_blank?(params[:patient_id])
      @patient_id = params[:patient_id]
    elsif !param_blank?(params[:mrn_nr])
      @patient_id = Patient.find_id_using_mrn(params[:mrn_nr])
    else
      error_found = true
      flash.now[:notice] = 'Please enter MRN or patient ID'  
    end
    
    @sample_characteristics = SampleCharacteristic.find_all_by_patient_id(@patient_id, :include => [:patient, :pathology, :samples],
                                                                          :conditions => "samples.source_sample_id IS NULL")
    if @sample_characteristics.size == 0
      error_found = true
      flash.now[:error] = 'Error - invalid patient id, or no samples exist for this patient'
    end
    
    if error_found
      @to_date = Date.today
      render :action => 'new_params'
      #render :action => :debug
      
    else
      # If a pathology record exists for this patient, go to index view to then either update the pathology record,
      # or add a new one.  Otherwise go directly to add new screen  
      @existing_pathology = Pathology.find_by_patient_id(@patient_id)
      if @existing_pathology && params[:add_new] == 'no'
        redirect_to :action => :index, :patient_id => @patient_id
      else
        @pathology = Pathology.new
        # Sample characteristics not already associated with a pathology report, will be available to be associated with a new pathology report
        @sample_characteristics.reject! {|schar| !schar.pathology_id.nil? }  #Remove sample characteristic records where pathology foreign key is not nil
        render :action => :new
      end
    end  
  end
  
  def create
    @pathology = Pathology.new(params[:pathology])
    
    if params[:sample_characteristic_id].nil?
      flash[:error] = 'At least one sample characteristic record must be checked for a new pathology report'
      redirect_to :action => :new, :patient_id => params[:pathology][:patient_id]
      
    elsif @pathology.save
      SampleCharacteristic.update_all(["pathology_id = ?", @pathology.id],
                                      ["sample_characteristics.id IN (?)", params[:sample_characteristic_id]])
      redirect_to pathologies_url(:patient_id => @pathology.patient_id)
      
    else
      flash[:error] = 'Error saving pathology details - Please contact system admin'
      redirect_to :action => :new, :patient_id => params[:pathology][:patient_id]
    end
  end

  def edit
    @pathology = Pathology.includes(:sample_characteristics => :samples).where('samples.source_sample_id IS NULL').find(params[:id])
  end

  def update
    @pathology = Pathology.find(params[:id])
    if @pathology.update_attributes(params[:pathology])
      flash[:notice] = 'Pathology report details were successfully updated.'
      redirect_to(@pathology)
    else
      dropdowns
      render :action => "edit"
    end
  end

  def show
    @pathology = Pathology.includes(:sample_characteristics => :samples).where('samples.source_sample_id IS NULL').find(params[:id])
  end

  def index
    if params[:patient_id]
      @patient_id             = params[:patient_id]
      @pathologies            = Pathology.includes(:sample_characteristics => :samples).where('samples.source_sample_id IS NULL').find_all_by_patient_id(params[:patient_id])
      @sample_characteristics = SampleCharacteristic.includes(:samples).where('samples.source_sample_id IS NULL AND pathology_id IS NULL').find_all_by_patient_id(params[:patient_id])
    else
      @pathologies = Pathology.includes(:sample_characteristics => :samples).where('samples.source_sample_id IS NULL')
    end
    render :action => :index
  end
  
  def destroy
    @pathology = Pathology.find(params[:id])
    @patient_id = @pathology.patient_id
    @pathology.destroy

    redirect_to pathologies_url(:patient_id => @patient_id)
  end

## Protected and private methods ##
protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Pathology']])
    @hpathology         = category_filter(@category_dropdowns, 'pathology')
    @pathology_dx       = category_filter(@category_dropdowns, 'pathology dx')
    @tumor_stage        = category_filter(@category_dropdowns, 'tumor stage')
    @tumor_T            = category_filter(@category_dropdowns, 'tumor_T')
    @tumor_N            = category_filter(@category_dropdowns, 'tumor_N')
    @tumor_M            = category_filter(@category_dropdowns, 'tumor_M')
  end
  
end