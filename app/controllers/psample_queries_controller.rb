class PsampleQueriesController < ApplicationController
  authorize_resource :class => ProcessedSample
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query
    @psample_query = PsampleQuery.new(:to_date   =>  Date.today)
  end
  
   def index
    @psample_query = PsampleQuery.new(params[:psample_query]) 
     
    if @psample_query.valid?
      condition_array = define_conditions(params)
      @processed_samples = ProcessedSample.find_for_query(condition_array)                                       
      render :action => :index
    else
      dropdowns
      render :action => :new_query
    end
    #render :action => 'debug'
  end
  
  def export_samples
    export_type = 'T'
    @processed_samples = ProcessedSample.find_for_export(params[:export_id])
    file_basename = ['LIMS_Extractions', Date.today.to_s].join("_")
    
    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_samples_csv(@processed_samples)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')
                  
      else # Use for debugging
        csv_string = export_samples_csv(@processed_samples, with_mrn)
        render :text => csv_string
    end
  end
  
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @protocols          = Protocol.find_for_protocol_type('E')  #Extraction protocols
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Clinical'], Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Extraction']])
    @clinics            = category_filter(@category_dropdowns, 'clinic')  
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @extraction_type    = category_filter(@category_dropdowns, 'extraction type')
  end
  
  def define_conditions(params)
    @sql_params = setup_sql_params(params)
    
    @where_select = []
    @where_values = []
    
    @sql_params.each do |attr, val|
      if !param_blank?(val)
        @where_select = add_to_select(@where_select, attr, val)
        @where_values = add_to_values(@where_values, attr, val)
      end
    end
    
    db_fld = 'processed_samples.processing_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:psample_query], db_fld)
    
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end
  
  def setup_sql_params(params)
    sql_params = {}
    
    # Standard case, just put sample_query attribute/value into sql_params hash
    params[:psample_query].each do |attr, val|
      sql_params[attr.to_sym] = val if !val.blank? && PsampleQuery::ALL_FLDS.include?("#{attr}")
    end
    
    if !params[:psample_query][:mrn].blank?
      patient_id, found = Patient.get_patient_id(params[:psample_query][:mrn])
      sql_params[:patient_id] = (patient_id ||= 0)
    end
    
    return sql_params 
  end
  
  def add_to_select(where_select, attr, val)
    if attr.to_s == 'barcode_key'
      where_select.push('processed_samples.barcode_key LIKE ?')
    else
      where_select.push("sample_characteristics.#{attr}" + sql_condition(val)) if PsampleQuery::SCHAR_FLDS.include?("#{attr}")
      where_select.push("samples.#{attr}" + sql_condition(val))                if PsampleQuery::SAMPLE_FLDS.include?("#{attr}")
      where_select.push("processed_samples.#{attr}" + sql_condition(val))      if PsampleQuery::PSAMPLE_FLDS.include?("#{attr}")
    end
    return where_select
  end
  
  def add_to_values(where_values, attr, val)
    if attr.to_s == 'barcode_key'
      return where_values.push([val,'%'].join)
    else
      return where_values.push(sql_value(val))
    end
  end

# Use a variation of the methods below if need to be more specific with barcode search #

#  def conditions_for_barcode(barcode_key)
#    rc_pattern = mask_barcode(params[:barcode_key])
#    if rc_pattern[0] == 'pattern' && rc_pattern[2].nil?
#      bc_select = 'processed_samples.barcode_key LIKE ?'
#      bc_condition = [rc_pattern[1]]
#      
#    elsif rc_pattern[0] == 'pattern'
#      bc_select = '(processed_samples.barcode_key LIKE ? OR processed_samples.barcode_key LIKE ?)'
#      bc_condition = [rc_pattern[1], rc_pattern[2]]
#      
#    else # rc_pattern[0] = 'exact'
#      bc_select = 'processed_samples.barcode_key = ?'
#      bc_condition = [params[:barcode_key]]
#    end 
#    return bc_select, bc_condition
#  end
#  
#  def mask_barcode(barcode_key)
#    barcode_split = barcode_key.split('.')
#    if barcode_split.length > 1 # processed sample barcode entered
#      return ['exact', barcode_key, nil]
#      
#    else  # source or dissected barcode (no '.')
#      last_char = barcode_key[-1,1] # last character of barcode
#      dissect_flag = (last_char =~ /[A-Z]/? true : false)
#      if dissect_flag == true
#        return ['pattern', [barcode_key, '.%'].join, nil]
#      else
#        return ['pattern', [barcode_key, '.%'].join, [barcode_key, '_.%'].join]
#      end  
#    end
#  end
  
  def export_samples_csv(processed_samples)    
    hdgs, flds = export_samples_setup
    
    csv_string = FasterCSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs
   
      processed_samples.each do |processed_sample|
        fld_array    = []
        sample_xref  = model_xref(processed_sample)
        
        flds.each do |obj_code, fld|
          obj = sample_xref[obj_code.to_sym]     
          if obj
            fld_array << obj.send(fld)
          else
            fld_array << nil
          end
        end    
        csv << [Date.today.to_s].concat(fld_array)
      end
    end
    return csv_string
  end
  
  def export_samples_setup
    hdgs  = (%w{DownloadDt Patient_ID Barcode Type FromSample ProcessDt Amt(ug) Conc A260/280 Rem? Room_Freezer Shelf Box_Bin})
    
    flds  = [['sm', 'patient_id'],
             ['ps', 'barcode_key'],
             ['ps', 'extraction_type'],
             ['sm', 'barcode_key'],
             ['ps', 'processing_date'],
             ['ps', 'final_amt_ug'],
             ['ps', 'final_conc'],
             ['ps', 'final_a260_a280'], 
             ['ps', 'psample_remaining'],
             ['lp', 'location_string'],
             ['ps', 'storage_shelf'],
             ['ps', 'storage_boxbin']]
             
    return hdgs, flds
  end
  
  def model_xref(psample)
    return {:ps => psample, :sm => psample.sample, :lp => psample.storage_location}
  end
    

 end