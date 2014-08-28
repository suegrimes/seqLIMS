class StorageQueriesController < ApplicationController
  authorize_resource :class => SampleLoc
  before_filter :dropdowns, :only => :new_query
  
  def new_query
    @storage_query = StorageQuery.new(:to_date   => Date.today)
  end
  
  def index
    @storage_query = StorageQuery.new(params[:storage_query])
    
    if @storage_query.valid?
      @condition_array = define_conditions(params)
      @sample_locs = SampleLoc.find_for_storage_query(@condition_array)
    
      flash.now[:notice] = 'No samples found for parameters entered' if @sample_locs.nil?
      render :action => 'index'
    
    else  # Validation errors found
      dropdowns
      render :action => :new_query
    end
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
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @clinics            = category_filter(@category_dropdowns, 'clinic')  
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
  end
  
  def define_conditions(params)
    @where_select = []
    @where_values = []

    params[:storage_query].each do |attr, val|
      if !param_blank?(val) && StorageQuery::ALL_FLDS.include?("#{attr}")
        @where_select.push("sample_characteristics.#{attr}" + sql_condition(val)) if StorageQuery::SCHAR_FLDS.include?("#{attr}")
        @where_select.push("samples.#{attr}" + sql_condition(val))                if StorageQuery::SAMPLE_FLDS.include?("#{attr}")
        @where_values.push(sql_value(val))
      end
    end

    date_fld = 'samples.sample_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:storage_query], date_fld)
    return (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
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
    hdgs  = hdg1.concat(%w{Barcode SampleType SampleDate Protocol OR_Designation Preservation PathologyDX
                           Histopathology FromSample Remaining? Room_Freezer Container})
    
    flds1  = [['sm', 'patient_id'],
             ['pt', 'mrn'],
             ['sm', 'barcode_key'],
             ['sm', 'sample_category'],
             ['sm', 'sample_date'],
             ['cs', 'consent_name'],
             ['sm', 'tumor_normal'],
             ['sm', 'tissue_preservation'],
             ['pr', 'pathology_classification'],
             ['he', 'histopathology'], 
             ['sm', 'source_barcode_key'],
             ['sm', 'sample_remaining'],
             ['ss', 'room_and_freezer'],
             ['ss', 'container_and_position']]
             
    flds2 = [['sm', 'patient_id'],
             ['pt', 'mrn'],
             ['ps', 'barcode_key'],
             ['ps', 'extraction_type'],
             ['ps', 'processing_date'],
             ['cs', 'consent_name'],
             ['sm', 'tumor_normal'],
             ['ps', 'blank'],
             ['ps', 'blank'], 
             ['ps', 'blank'], 
             ['sm', 'barcode_key'],
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
