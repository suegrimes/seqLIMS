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
      if @condition_array.size > 0 && @condition_array[0] == '**error**'
        dropdowns
        flash.now[:error] = "Error in sequencing library barcode parameters, please enter digits only"
        render :action => :new_query
      else
        mplex = (params[:excl_splex] && params[:excl_splex] == 'N') ? 'A' : 'M'
        @seq_libs        = SeqLib.find_for_query(sql_where(@condition_array), mplex)
        # Use sort instead of sort_by, so that preparation_date can be sorted in descending order
        #@seq_libs = @seq_libs.sort_by { |a| [a.preparation_date, a.lib_name] }
        @seq_libs.sort! { |a,b| dt_sort       = b.preparation_date <=> a.preparation_date
                                dt_sort.zero? ? b.barcode_key      <=> a.barcode_key     : dt_sort }
        render :action => :index
      end
    
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
    
    params[:seqlib_query].each do |attr, val|
      if !param_blank?(val)
        if SeqlibQuery::SEQLIB_FLDS.include?(attr)
          @where_select.push("seq_libs.#{attr}" + sql_condition(val))
          @where_values.push(sql_value(val))
        elsif SeqlibQuery::PSAMPLE_FLDS.include?(attr)
          @where_select.push("processed_samples.#{attr}" + sql_condition(val))
          @where_values.push(sql_value(val))
        elsif SeqlibQuery::SEARCH_FLDS.include?(attr)
          @where_select.push("seq_libs.#{attr} LIKE ?")
          @where_values.push(sql_value("%#{val}%"))
        end
      end
    end
    
    unless (params[:incl_used] && params[:incl_used] == 'Y')
      @where_select.push("seq_libs.lib_status <> 'F'")
    end

    if !param_blank?(params[:seqlib_query][:barcode_string])
      str_vals, str_ranges, errors = compound_string_params('L', 6, params[:seqlib_query][:barcode_string])
      if errors.size > 0
        return ['**error**']
      else
        where_select, where_values   = sql_compound_condition('seq_libs.barcode_key', str_vals, str_ranges)
        @where_select.push(where_select)
        @where_values.push(*where_values)
      end
    end
    
    date_fld = 'seq_libs.preparation_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:seqlib_query], date_fld)
    
    sql_where_clause = (@where_select.empty? ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
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
    hdgs  = %w{Download_Dt Barcode PatientID LibName Owner PrepDt LibType Adapter SampleConc(ng/ul) SampleConc(nM)
               Project OligoPool AlignRef SeqLaneCt}

    flds  = [['sl', 'lib_barcode'],
             ['sl', 'patient_ids'],
             ['sl', 'lib_name'],
             ['sl', 'owner_abbrev'],
             ['sl', 'preparation_date'],
             ['sl', 'library_type'],
             ['sl', 'adapter_name'],
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