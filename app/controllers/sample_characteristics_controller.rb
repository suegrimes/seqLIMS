class SampleCharacteristicsController < ApplicationController
  load_and_authorize_resource
  protect_from_forgery :except => :add_new_sample
  
  before_filter :dropdowns, :only => [:new_sample, :edit]
  before_filter :sample_dropdowns, :only => [:new_sample, :edit, :add_new_sample]
  
  ## Start of actively used methods ##
  def new
  end
  
  def new_sample
    authorize! :create, SampleCharacteristic
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
       @sample_characteristic.samples.each do |sample|
         sample.build_sample_storage_container
       end
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
    @sample_characteristic = SampleCharacteristic.new(params[:sample_characteristic])
                                        
    if @sample_characteristic.save
      flash[:notice] = 'New clinical sample was successfully saved'
      
      # Sample Characteristic successfully saved => send emails
      sample = new_sample_entered(@sample_characteristic.id, params[:sample_characteristic])
      email  = send_email(sample, @patient.mrn, current_user) unless sample.nil? || EMAIL_CREATE[:samples] == 'NoEmail'
      if EMAIL_DELIVERY[:samples]  == 'Debug'
        render(:text => "<pre>" + email.encoded + "</pre>")
      else
        redirect_to :action => 'show', :id => @sample_characteristic.id, :added_sample_id => @sample_characteristic.samples[-1].id
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
    
    if @sample_characteristic.update_attributes(params[:sample_characteristic])
      flash[:notice] = 'Clinical sample characteristics successfully updated'
      
      # Sample Characteristic successfully saved; send emails if new sample was added
      sample = new_sample_entered(params[:id], params[:sample_characteristic])
      if !sample.nil?
        email  = send_email(sample, @sample_characteristic.patient.mrn, current_user) unless EMAIL_CREATE[:samples] == 'NoEmail'
        if EMAIL_DELIVERY[:samples] == 'Debug'
          render(:text => "<pre>" + email.encoded + "</pre>")
        else
          redirect_to :action => 'show', :id => @sample_characteristic.id, :added_sample_id => sample.id
        end
      else
        redirect_to(@sample_characteristic)
      end
      
    else
      flash[:error] = 'Error - Clinical sample/characteristics not updated'
      dropdowns
      sample_dropdowns
      render :action => 'show'
    end
    #render :action => 'debug'
  end
  
  # GET /patients/1
  def show
    params[:added_sample_id] ||= 0
    @addnew_link = 'no'
    @sample_characteristic = SampleCharacteristic.find(params[:id], :include => [:consent_protocol, :samples])
    if params[:added_sample_id].to_i > 0
      @added_sample_id = params[:added_sample_id]
      @sample_params = build_params_from_obj(Sample.find(@added_sample_id), Sample::FLDS_FOR_COPY)
      sample_dropdowns
    end
  end
  
#   DELETE /patients/1
  def destroy
    @sample_characteristic = SampleCharacteristic.find(params[:id])
    @sample_characteristic.destroy  
    redirect_to(patient_url)
  end
  
  def add_new_sample
    @sample_characteristic = SampleCharacteristic.find(params[:id])
    @patient_id = @sample_characteristic.patient_id

    if params[:from_sample_id]
      sample = @sample_characteristic.samples.build(build_params_from_obj(Sample.find(params[:from_sample_id]), Sample::FLDS_FOR_COPY))
    else
      sample = @sample_characteristic.samples.build
    end
    render :update do |page|
      page.replace_html 'add_more', :partial => 'samples_form', :locals => {:sample => sample}
    end
  end


## Protected and private methods ##
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @races              = category_filter(@category_dropdowns, 'race')
    @ethnicity          = category_filter(@category_dropdowns, 'ethnicity')
    @clinics            = category_filter(@category_dropdowns, 'clinic')
    #@etiology         = Category.populate_dropdown_for_category('etiology')
    #@diagnosis        = Category.populate_dropdown_for_category('diagnosis')
  end
  
  def sample_dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @sample_units       = category_filter(@category_dropdowns, 'sample unit')
    @vial_types         = category_filter(@category_dropdowns, 'vial type')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure')
    @freezer_locations  = FreezerLocation.list_all_by_room
    @containers         = category_filter(@category_dropdowns, 'container')
  end
  
private
  def owner_email(consent_protocol)
    case EMAIL_CREATE[:samples]
      when 'NoEmail', 'Test'
        return nil
      when 'Test1', 'Prod'
        return (consent_protocol && !consent_protocol.email_confirm_to.blank? ? consent_protocol.email_confirm_to : nil)
    end
  end
  
  def new_sample_entered(sample_characteristic_id, params)
    if params[:new_sample_attributes]
      barcode_key = params[:new_sample_attributes][0][:barcode_key]
      if !barcode_key.nil? && !barcode_key.blank?
        sample = Sample.find_newly_added_sample(sample_characteristic_id, barcode_key)
      end
    end
    return sample
  end

  def send_email(sample, mrn, user)
    consent_protocol = ConsentProtocol.find(sample.sample_characteristic.consent_protocol_id) 
    email = LimsMailer.create_new_sample(sample, mrn, user.login, owner_email(consent_protocol))
    email.set_content_type("text/html")
    LimsMailer.deliver(email) unless EMAIL_DELIVERY[:samples] == 'Debug'
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
    
end
