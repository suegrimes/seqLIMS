class PatientsController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => :edit
  
  # GET /patients
  def index
    @patients = Patient.select('id, gender, race, ethnicity, clinical_id_encrypted').includes(:samples).all
  end

  # GET /patients/1
  def show
    @patient = Patient.includes(:sample_characteristics => :samples).find(params[:id])
  end

  def edit_params
    if request.post?
      if !param_blank?(params[:mrn])
        patient_id = Patient.find_id_using_mrn(params[:mrn])
      elsif !param_blank?(params[:patient_id])
        patient_id = params[:patient_id]
      end
      
      if patient_id && Patient.exists?(patient_id)
        redirect_to :action => :edit, :id => patient_id
      else
        flash[:error] = 'Patient identifier not entered, or not found - please try again'
        render :action => :edit_params, :params => params
      end    
      
    end
  end

  # GET /patients/1/edit
  def edit
    @patient = Patient.find(params[:id])
  end
  
  def query_params
    
  end
  
  def loadtodb
    @file_path = "#{Rails.root}/public/files/clin_precs_2.txt"
    
    if FileTest.file?(@file_path)
      recs_loaded = Patient.loadrecs(@file_path)
      flash[:notice] = "#{recs_loaded} patient ids loaded and encrypted"
    else
      flash[:notice] = "File: #{@file_path} not found"
    end
    
    render :action => 'debug'
  end

  # PUT /patients/1
  def update
    @patient = Patient.find(params[:id])
    
    if @patient.update_attributes(params[:patient])
      flash[:notice] = 'Patient was successfully updated.'
      redirect_to(@patient)
    else
      render :action => "edit"
    end
  end

  # DELETE /patients/1
  def destroy
    @patient = Patient.find(params[:id])
    @patient.destroy
    flash[:notice] = "Patient #{params[:id]} was successfully deleted"
    redirect_to "/"
  end

protected  
  def dropdowns
    @races            = Category.populate_dropdown_for_category('race')
    @ethnicity        = Category.populate_dropdown_for_category('ethnicity')
  end
  
  def check_for_existing_mrn(mrn)
    patients   = Patient.all.map {|patient| [patient.mrn, patient.id]}
    patient_id = patients.assoc(mrn)
    return patient_id[1]
  end
  
end
