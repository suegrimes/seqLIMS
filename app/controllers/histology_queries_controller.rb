class HistologyQueriesController < ApplicationController
  authorize_resource :class => Histology
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query
    @histology_query = HistologyQuery.new(:from_date => (Date.today - 2.years).beginning_of_month,
                                          :to_date   =>  Date.today)
  end
 
  def index
    @histology_query = HistologyQuery.new(params[:histology_query])
    
    if @histology_query.valid?
      @condition_array = define_conditions(params)
      if @condition_array.size > 0 && @condition_array[0] == '**error**'
        dropdowns
        flash.now[:error] = "Error in sample barcode parameters, please enter alphanumeric only"
        render :action => :new_query
      else
        @hdr = 'H&E Details (Filtered)'
        @histologies = Histology.find_with_conditions(@condition_array)
        render :action => :index
      end
      
    else
      dropdowns
      render :action => :new_query
    end
  end

protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @clinics            = Category.populate_dropdown_for_category('clinic')
    @preservation       = Category.populate_dropdown_for_category('tissue preservation')
  end
  
  def define_conditions(params)
    @sql_params = setup_sql_params(params)
    @where_select = []
    @where_values = []
    
    @sql_params.each do |attr, val|
      if !param_blank?(val) && HistologyQuery::ALL_FLDS.include?("#{attr}")
        @where_select.push("sample_characteristics.#{attr}" + sql_condition(val)) if HistologyQuery::SCHAR_FLDS.include?("#{attr}")
        @where_select.push("samples.#{attr}" + sql_condition(val))                if HistologyQuery::SAMPLE_FLDS.include?("#{attr}")
        @where_values.push(sql_value(val))
      end
    end

    if !param_blank?(params[:histology_query][:barcode_string])
      str_vals, str_ranges, errors = compound_string_params('', nil, params[:histology_query][:barcode_string])
      if errors.size > 0
        return ['**error**']
      else
        where_select, where_values   = sql_compound_condition('samples.barcode_key', str_vals, str_ranges)
        @where_select.push(where_select)
        @where_values.push(*where_values)
      end
    end

    date_fld = 'histologies.he_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:histology_query], date_fld)
    return (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
  end

  def setup_sql_params(params)
    sql_params = {}

    # Standard case, just put sample_query attribute/value into sql_params hash
    params[:histology_query].each do |attr, val|
      sql_params["#{attr}"] = val if !val.blank? && HistologyQuery::ALL_FLDS.include?("#{attr}")
    end

    if !params[:histology_query][:mrn].blank?
      patient_id = Patient.find_id_using_mrn(params[:histology_query][:mrn])
      sql_params['patient_id'] = (patient_id ||= 0)
    end

    return sql_params
  end

end