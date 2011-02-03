class SampleCharacteristicsController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new_sample, :edit]
  before_filter :sample_dropdowns, :only => [:new_sample, :edit]
  
  ## Start of actively used methods ##
  def new
  end
  
  def new_sample
    unauthorized! if cannot? :create, SampleCharacteristic
    error_found = false
    
    if !param_blank?(params[:patient_id])
      @patient_id       = params[:patient_id]
      new_patient       = false
    elsif !param_blank?(params[:mrn_nr])
      @patient_id, new_patient = Patient.get_patient_id(params[:mrn_nr], 'add')
    else
      error_found = true
      flash.now[:error] = 'Error - invalid patient id/mrn# (cannot be blank)'  
    end
    
    if !error_found
      @patient = Patient.find_by_id(@patient_id)
      if new_patient
        @sample_characteristic = SampleCharacteristic.new(:patient_id => @patient_id,
                                                          :collection_date => Date.today)
      else
        @existing_sample = SampleCharacteristic.find_by_patient_id(params[:patient_id])
        if @existing_sample
          clinic_or_location = @existing_sample.clinic_or_location
          consent_protocol_id = @existing_sample.consent_protocol_id
        end
        
        @sample_characteristic = SampleCharacteristic.new(:patient_id => @patient.id,
                                                           :gender => @patient.gender,
                                                           :ethnicity => @patient.ethnicity,
                                                           :race => @patient.race,
                                                           :collection_date => Date.today,
                                                           :clinic_or_location => clinic_or_location,
                                                           :consent_protocol_id => consent_protocol_id)  
       end 
       
       @sample_characteristic.samples.build
       params[:new_patient] = new_patient 
       render :action => 'new_sample'
       #render :action => 'debug'
    else
      dropdowns
      render :action => 'new'
      #render :action => 'debug'
    end
    
  end
  
   # POST /sample_characteristics/1
  def create 
    @patient = Patient.find(params[:patient][:id])
    @patient.update_attributes(params[:patient])
    
    params[:sample_characteristic].merge!(:patient_id  => params[:patient][:id])
    
    # Need error checking for protocol not found?
    #(Not found should not occur, since selection is from drop-down box)
    if !param_blank?(params[:sample_characteristic][:consent_protocol_id])
      consent_nr = ConsentProtocol.find(params[:sample_characteristic][:consent_protocol_id]).consent_nr
      params[:sample_characteristic].merge!(:consent_nr => consent_nr)
    end
  
    @sample_characteristic = SampleCharacteristic.new(params[:sample_characteristic])
                                        
    if @sample_characteristic.save
      flash[:notice] = 'New clinical sample was successfully saved'
      
      # Sample Characteristic successfully saved => send emails
      email  = send_email(@sample_characteristic, @patient.mrn, current_user) if LimsMailer::MAIL_FLAG != 'Dev'
      if LimsMailer::DELIVER_FLAG  == 'Debug'
        render(:text => "<pre>" + email.encoded + "</pre>")
      else
        redirect_to :action => 'show', :id => @sample_characteristic.id, :addnew_link => 'yes'
      end
      
    # Error in saving Sample Characteristic
    else
      dropdowns
      sample_dropdowns
      render :action => 'new_sample' 
    end
  end
  
  def edit_params
    if request.post?
      condition_array = define_conditions(params)
    
      if condition_array.nil?
        flash[:error] = 'Please select at least one parameter for this query'
        render :action => 'edit_params'
        
      else
        @nr_samples, @clin_samples_by_patient = SampleCharacteristic.find_and_group_with_conditions(condition_array)
        if @nr_samples > 1
          render :action => 'list_for_edit'
          
        elsif @nr_samples == 1
          @clin_samples_by_patient.sort.each do | patient_id, sample_characteristics|
            @sample_characteristic_id = sample_characteristics[0].id
          end
          redirect_to :action => 'edit', :id => @sample_characteristic_id
          
        else
          flash[:error] = 'No sample characteristics found for this patient or barcode'
          render :action => 'edit_params'
        end
      end
      
    else
      render :action => 'edit_params'
    end
  end
  
  # GET /sample_characteristics/1/edit
  def edit
    @sample_characteristic = SampleCharacteristic.find(params[:id], :include => :samples,
                                                       :conditions => "samples.source_sample_id IS NULL")
  end
  
  # PUT /sample_characteristics/1
  def update 
    @sample_characteristic = SampleCharacteristic.find(params[:id])
    
    # Need error checking for protocol not found?
    #(Not found should not occur, since selection is from drop-down box)
    if !param_blank?(params[:sample_characteristic][:consent_protocol_id])
      consent_nr = ConsentProtocol.find(params[:sample_characteristic][:consent_protocol_id]).consent_nr
      params[:sample_characteristic].merge!(:consent_nr => consent_nr)
    end
    
    if @sample_characteristic.update_attributes(params[:sample_characteristic])
      flash[:notice] = 'Clinical sample characteristics successfully updated'
      redirect_to(@sample_characteristic)
    else
      dropdowns
      sample_dropdowns
      render :action => 'edit' 
    end
  end
  
  # GET /patients/1
  def show
    @addnew_link = (params[:addnew_link] ||= 'no')
    #@addnew_link = 'yes'
    @sample_characteristic = SampleCharacteristic.find(params[:id], :include => [:consent_protocol, :samples])
  end
  
#   DELETE /patients/1
  def destroy
    @sample_characteristic = SampleCharacteristic.find(params[:id])
    @sample_characteristic.destroy  
    redirect_to(patient_url)
  end

## Protected and private methods ##
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @races              = category_filter(@category_dropdowns, 'race')
    @ethnicity          = category_filter(@category_dropdowns, 'ethnicity')
    @clinics            = category_filter(@category_dropdowns, 'clinic')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    #@etiology         = Category.populate_dropdown_for_category('etiology')
    #@diagnosis        = Category.populate_dropdown_for_category('diagnosis')
  end
  
  def sample_dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @sample_units       = category_filter(@category_dropdowns, 'sample unit')
    @vial_types         = category_filter(@category_dropdowns, 'vial type')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure')
    @storage_locations  = StorageLocation.list_all_by_room
  end
  
private
  def owner_email(consent_protocol)
    case LimsMailer::MAIL_FLAG
      when 'Dev', 'Test1'
        return nil
      when 'Test2', 'Prod'
        return (consent_protocol && !consent_protocol.email_confirm_to.blank? ? consent_protocol.email_confirm_to : nil)
    end
  end

  def send_email(sample_characteristic, mrn, user)
    consent_protocol = ConsentProtocol.find(sample_characteristic.consent_protocol_id) 
    email = LimsMailer.create_new_sample(sample_characteristic, mrn, user.login, owner_email(consent_protocol))
    email.set_content_type("text/html")
    LimsMailer.deliver(email) unless LimsMailer::DELIVER_FLAG == 'Debug'
    return email
  end
  
  def define_conditions(params)
    @where_select = []; @where_values = []
    
    if !params[:patient_id].blank?
      @where_select.push("samples.patient_id = ?")
      @where_values.push(params[:patient_id])
    elsif !params[:mrn].blank?
      patient_id, found = Patient.get_patient_id(params[:mrn])
      @where_select.push("samples.patient_id = ?")
      @where_values.push(patient_id ||= 0)
    end 
    
    if !params[:barcode_key].blank?
      @where_select.push("samples.barcode_key = ?")
      @where_values.push(params[:barcode_key])
    end  
    
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end
  
#  def define_conditions(params)
#    condition_array = []
#    condition_array[0] = 'blank' # if parameters are entered, this will be replaced with SQL where conditions
#    select_conditions = []
#    
#    if !params[:mrn].blank? || !params[:patient_id].blank?
#      pt_select, pt_conditions = conditions_for_patient(params, 'samples')
#      select_conditions.push(pt_select) 
#      condition_array.push(pt_conditions)
#    end
#    
#    if !param_blank?(params[:barcode_key])
#      select_conditions.push('samples.barcode_key = ?')
#      condition_array.push(params[:barcode_key])
#    end
#    
#    if select_conditions.length == 0
#      return []
#    else
#      condition_array[0] = select_conditions.join(' AND ')
#      return condition_array
#    end
#    
#  end
    
end
