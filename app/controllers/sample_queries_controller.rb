class SampleQueriesController < ApplicationController
  authorize_resource :class => Sample
  before_filter :dropdowns, :only => :new_query
  
  def new_query
    @sample_query = SampleQuery.new(:to_date   => Date.today)
    @type_of_sample = (params[:stype] ||= 'Source and Dissected')
  end
  
  def index
    params[:rpt_type] ||= 'tree'
    @type_of_sample = (params[:stype] ||= ' ')
    
    @sample_query = SampleQuery.new(params[:sample_query])
    
    if @sample_query.valid?
      @condition_array = define_conditions(params)
      @nr_samples, @samples_by_patient = Sample.find_and_group_by_source(sql_where(@condition_array))
      @source_sample_ids = Sample.find_all_source_for_dissected
      
      @type_of_sample = (params[:stype] ||= 'Source and Dissected')
      @heading_string = ''
  
      if !@nr_samples
        @nr_samples = [0,0]
        @samples_by_patient = nil
      end
    
      flash.now[:notice] = 'No samples found for parameters entered' if @nr_samples == 0
   
      if params[:rpt_type] == 'tree'
        render :action => 'list_as_tree'
      else
        render :action => 'index'
      end
    
    else  # Validation errors found
      dropdowns
      render :action => :new_query
    end
  end
  
  def list_samples_for_patient
    @type_of_sample = (params[:stype] ||= ' ')
    
  # List samples for specific patient, and (optionally) source sample
  #   if params[:sample_id] or params[:sample_characteristic_id] also supplied, find patient id from model object
    if params[:sample_id] 
      @patient_nrs = find_patient_nr('Sample', params[:sample_id])
    elsif params[:sample_characteristic_id]
      @patient_nrs = find_patient_nr('SampleCharacteristic', params[:sample_characteristic_id])
    elsif params[:patient_id]
      @patient_nrs = format_patient_nr(params[:patient_id], 'array')
    end
      
    if @patient_nrs
      @nr_samples, @samples_by_patient = Sample.find_and_group_for_patient(@patient_nrs[0])
      @heading_string  = 'Patient: ' + format_patient_nr(@patient_nrs[0])   
    end
    
    if !@nr_samples
        @nr_samples = [0,0]
        @samples_by_patient = nil
        @heading_string = ''
    end
    
    render :action => 'index'
  end
  
  def list_samples_for_characteristic
  # All samples for a particular patient & sample_characteristic
  # Heading includes patient id/mrn, and sample collection date 
    @type_of_sample = (params[:stype] ||= ' ')
    
    if params[:sample_characteristic_id]
      patient_nrs = find_patient_nr('SampleCharacteristic', params[:sample_characteristic_id])
      @nr_samples, @samples_by_patient = Sample.find_and_group_for_clinical(params[:sample_characteristic_id])
      if SampleCharacteristic.exists?(params[:sample_characteristic_id])
        @collection_date = SampleCharacteristic.find(params[:sample_characteristic_id]).collection_date.to_s
      else
        @collection_date = ' '
      end
        @heading_string  = 'Patient: ' + format_patient_nr(patient_nrs[0]) + ' , ' + 
                           'Collection Date: '  + @collection_date
  
    elsif params[:source_sample_id]
      # All samples for a particular patient & source sample
      # Heading includes patient id/mrn, and source sample barcode
      patient_nrs = find_patient_nr('Sample', params[:source_sample_id])
      @nr_samples, @samples_by_patient = Sample.find_and_group_for_sample(params[:source_sample_id])
      @heading_string  = 'Patient: ' + format_patient_nr(patient_nrs[0]) + ' , ' + 
                         'Sample: '  + find_barcode('Sample', params[:source_sample_id])
    end
    
    if !@nr_samples
        @nr_samples = [0,0]
        @samples_by_patient = nil
        @heading_string = ''
    end
    
    #render :action => :debug
    render :action => 'index'
  end
  
  def export_samples
    export_type = 'T'
    @samples = Sample.find_for_export(params[:export_id])
    file_basename = ['LIMS_Samples', Date.today.to_s].join("_")
    
    with_mrn = ((can? :read, Patient)? 'yes' : 'no')
    
    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_samples_csv(@samples, with_mrn)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')
                  
      else # Use for debugging
        csv_string = export_samples_csv(@samples, with_mrn)
        render :text => csv_string
    end
  end
  
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical'], Cgroup::CGROUPS['Pathology']])
    @races              = category_filter(@category_dropdowns, 'race', 'query')
    @ethnicities        = category_filter(@category_dropdowns, 'ethnicity', 'query')
    @clinics            = category_filter(@category_dropdowns, 'clinic', 'query')
    @sample_type        = category_filter(@category_dropdowns, 'sample type', 'query')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue', 'query')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation', 'query')
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal', 'query')
    @pathology          = category_filter(@category_dropdowns, 'pathology', 'query')
    @users              = User.populate_dropdown
  end
  
  def define_conditions(params)
    @sql_params = setup_sql_params(params)
    
    @where_select = []
    @where_values = []
    
    if params[:stype] == 'clinical' || params[:stype] == 'dissected'
      null_or_not = (params[:stype] == 'clinical' ? 'NULL' : 'NOT NULL')
      @where_select.push("samples.source_sample_id IS #{null_or_not}")
    end
    
    @sql_params.each do |attr, val|
      if !param_blank?(val)
        @where_select = add_to_select(@where_select, attr, val)
        @where_values = add_to_values(@where_values, attr, val)
      end
    end

    if !param_blank?(params[:sample_query][:barcode_string])
      str_vals, str_ranges, errors = compound_string_params('', nil, params[:sample_query][:barcode_string])
      where_select, where_values   = sql_compound_condition('samples.barcode_key', str_vals, str_ranges)
      #puts errors if !errors.blank?
      @where_select.push(where_select)
      @where_values.push(*where_values)
    end
    
    db_fld = (params[:sample_query][:date_filter] == 'Dissection Date' ? 'samples.sample_date' : 'sample_characteristics.collection_date')
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:sample_query], db_fld)
    
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end
  
  def setup_sql_params(params)
    sql_params = {} 
    
    # Standard case, just put sample_query attribute/value into sql_params hash
    params[:sample_query].each do |attr, val|
      sql_params["#{attr}"] = val if !val.blank? && SampleQuery::ALL_FLDS.include?("#{attr}")
    end
    
    if !params[:sample_query][:mrn].blank?
      patient_id = Patient.find_id_using_mrn(params[:sample_query][:mrn])
      sql_params['patient_id'] = (patient_id ||= 0)
    end
    
    return sql_params 
  end
  
  def add_to_select(where_select, attr, val)
    if attr.to_s == 'barcode_key'
      where_select.push('(samples.barcode_key = ? OR samples.source_barcode_key = ?)')
    else
      where_select.push("sample_characteristics.#{attr}" + sql_condition(val)) if SampleQuery::SCHAR_FLDS.include?("#{attr}")
      where_select.push("samples.#{attr}" + sql_condition(val))                if SampleQuery::SAMPLE_FLDS.include?("#{attr}")
      where_select.push("histologies.#{attr}" + sql_condition(val))            if SampleQuery::HISTOPATH_FLDS.include?("#{attr}")
    end
    return where_select
  end
  
  def add_to_values(where_values, attr, val)
    if attr.to_s == 'barcode_key'
      return where_values.push(val, val)
    else
      return where_values.push(sql_value(val))
    end
  end
  
  def export_samples_csv(samples, with_mrn='no')    
    hdgs, flds1, flds2 = export_samples_setup(with_mrn)
    
    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs
   
      samples.each do |sample|
        fld_array    = []
        sample_xref  = model_xref(sample)
        
        flds1.each do |obj_code, fld|
          obj = sample_xref[obj_code.to_sym]     
          if obj
            fld_array << obj.send(fld) unless (fld == 'mrn' && with_mrn == 'no')
          else
            fld_array << nil
          end
        end    
        csv << [Date.today.to_s].concat(fld_array)
        
        sample.processed_samples.each do |processed_sample|
          fld_array = []
          psample_xref = model_xref(sample, processed_sample)
          
          flds2.each do |obj_code, fld|
            obj = psample_xref[obj_code.to_sym]
          
            if obj && fld != 'blank'
              fld_array << obj.send(fld) unless (fld == 'mrn' && with_mrn == 'no')
            else
              fld_array << nil
            end
          end
        csv << [Date.today.to_s].concat(fld_array) 
        end
      end
    end
    return csv_string
  end
  
  def export_samples_setup(with_mrn='no')
    hdg1  =(with_mrn == 'yes'? ['Download_Dt', 'PatientID', 'MRN'] : ['Download_Dt', 'PatientID'])
    hdgs  = hdg1.concat(%w{Barcode SampleType SampleDate Protocol PatientDX OR_Designation Preservation
                           FromSample Histopathology Remaining? Room_Freezer Container})
    
    flds1  = [['sm', 'patient_id'],
             ['pt', 'mrn'],
             ['sm', 'barcode_key'],
             ['sm', 'sample_category'],
             ['sm', 'sample_date'],
             ['cs', 'consent_name'],
             ['pr', 'pathology_classification'],
             ['sm', 'tumor_normal'],
             ['sm', 'tissue_preservation'],
             ['sm', 'source_barcode_key'],
             ['he', 'histopathology'],
             ['sm', 'sample_remaining'],
             ['ss', 'room_and_freezer'],
             ['ss', 'container_and_position']]
             
    flds2 = [['sm', 'patient_id'],
             ['pt', 'mrn'],
             ['ps', 'barcode_key'],
             ['ps', 'extraction_type'],
             ['ps', 'processing_date'],
             ['cs', 'consent_name'],
             ['ps', 'blank'],
             ['sm', 'tumor_normal'],
             ['ps', 'blank'],
             ['sm', 'barcode_key'],
             ['ps', 'blank'],
             ['ps', 'psample_remaining'],
             ['pc', 'room_and_freezer'],
             ['pc', 'container_and_position']]
             
    return hdgs, flds1, flds2
  end
  
  def model_xref(xsample, psample=nil)
    sample_xref = {:pt => xsample.patient,
                   :sm => xsample,
                   :sc => xsample.sample_characteristic,
                   :cs => xsample.sample_characteristic.consent_protocol,
                   :pr => xsample.sample_characteristic.pathology,
                   :he => xsample.histology,
                   :ss => xsample.sample_storage_container}
    sample_xref.merge!({:ps => psample, :pc => psample.sample_storage_container}) if psample
    return sample_xref
  end
    
end
