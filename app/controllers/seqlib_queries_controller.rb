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
      @seq_libs        = SeqLib.find_for_query(@condition_array)
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
  
end 