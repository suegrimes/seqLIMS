class SeqlibQueriesController < ApplicationController
  #load_and_authorize_resource 
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query
   authorize! :read, SeqLib
   @seqlib_query = SeqlibQuery.new(:from_date => (Date.today - 12.months).beginning_of_month,
                                   :to_date   =>  Date.today)
  end
  
  # GET /seq_libs
  def index
    authorize! :read, SeqLib
    
    @seqlib_query = SeqlibQuery.new(params[:seqlib_query])
    
    if @seqlib_query.valid?
    
      @condition_array = define_conditions(params)
      @seq_libs        = SeqLib.find_for_query(sql_where(@condition_array))
      # Use sort instead of sort_by, so that preparation_date can be sorted in descending order
      #@seq_libs = @seq_libs.sort_by { |a| [a.preparation_date, a.lib_name] }
      @seq_libs.sort! { |a,b| dt_sort       = b.preparation_date <=> a.preparation_date
                              dt_sort.zero? ? b.barcode_key      <=> a.barcode_key     : dt_sort }
      render :action => :index
    
    else
      dropdowns
      render :action => :new_query
    end
  end

  def export_seqlibs
    export_type = 'T'
    @seq_libs = SeqLib.find_all_for_export(params[:export_id])
    file_basename = ['LIMS_SeqLibs', Date.today.to_s].join("_")

    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_seqlibs_csv(@seq_libs)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')

      else # Use for debugging
        csv_string = export_seqlibs_csv(@processed_samples, with_mrn)
        render :text => csv_string
    end
  end
  
protected
  def dropdowns
    @owners    = Researcher.populate_dropdown('incl_inactive')
    @projects  = SeqLib.unique_projects
    @align_refs = AlignmentRef.populate_dropdown
  end
  
  def define_conditions(params)
    @where_select = []
    @where_values = []
    @sql_params = setup_sql_params(params)
    
    @sql_params.each do |attr, val|
      if !param_blank?(val)
        @where_select = add_to_select(@where_select, attr, val)
        @where_values = add_to_values(@where_values, attr, val)
      end
    end
    
    if params[:excl_used] && params[:excl_used] == 'Y'
      @where_select.push("seq_libs.lib_status <> 'F'")
    end
    
    if !param_blank?(params[:seqlib_query][:barcode_from]) && param_blank?(params[:seqlib_query][:barcode_to])
      params[:seqlib_query][:barcode_to] = params[:seqlib_query][:barcode_from]
    end
    
    if !param_blank?(params[:seqlib_query][:barcode_from]) || !param_blank?(params[:seqlib_query][:barcode_to])
      @where_select.push("seq_libs.barcode_key LIKE 'L%'")
      @where_select, @where_values = sql_conditions_for_range(@where_select, @where_values, 
                                                            params[:seqlib_query][:barcode_from], params[:seqlib_query][:barcode_to],
                                                            "CAST(SUBSTRING(seq_libs.barcode_key,2) AS UNSIGNED)")
    end    
    
    date_fld = 'seq_libs.preparation_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:seqlib_query], date_fld)
    
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end
  
  def setup_sql_params(params)
    sql_params = {}
    
    # Standard case, just put sample_query attribute/value into sql_params hash
    params[:seqlib_query].each do |attr, val|
      sql_params[attr.to_sym] = val if !val.blank? && SeqlibQuery::ALL_FLDS.include?("#{attr}")
    end
    
    return sql_params 
  end
  
  def add_to_select(where_select, attr, val)
    if attr.to_s == 'lib_name'
      where_select.push("seq_libs.#{attr} LIKE ?")
    else
      where_select.push("seq_libs.#{attr}" + sql_condition(val)) if SeqlibQuery::SEQLIB_FLDS.include?("#{attr}")
    end
    return where_select
  end
  
  def add_to_values(where_values, attr, val)
    if attr.to_s == 'lib_name'
      return where_values.push(['%', val, '%'].join)
    else
      return where_values.push(sql_value(val))
    end
  end

  def export_seqlibs_csv(seq_libs)
    hdgs, flds = export_seqlibs_setup

    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs

      seq_libs.each do |seq_lib|
        fld_array    = []
        seq_lib_xref  = model_xref(seq_lib)

        flds.each do |obj_code, fld|
          obj = seq_lib_xref[obj_code.to_sym]
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

  def export_seqlibs_setup
    hdgs  = %w{Download_Dt Barcode PatientID LibName Owner PrepDt LibType Adapter SampleConc Project OligoPool
                           AlignRef SeqCt}

    flds  = [['sl', 'lib_barcode'],
             ['sl', 'patient_ids'],
             ['sl', 'lib_name'],
             ['sl', 'owner_abbrev'],
             ['sl', 'preparation_date'],
             ['sl', 'library_type'],
             ['sl', 'runtype_adapter'],
             ['sl', 'sample_conc_ngul'],
             ['sl', 'sample_conc_nm'],
             ['sl', 'project'],
             ['sl', 'oligo_pool'],
             ['sl', 'alignment_ref'],
             ['sl', 'flow_lane_ct']]

    return hdgs, flds
  end

  def model_xref(seq_lib)
    sample_xref = {:sl => seq_lib}
    return sample_xref
  end
end 