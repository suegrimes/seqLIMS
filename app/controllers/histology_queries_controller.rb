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
      @hdr = 'H&E Details (Filtered)'
      @histologies = Histology.find_with_conditions(@condition_array)
      render :action => :index
      
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
    @where_select = []
    @where_values = []
    
    params[:histology_query].each do |attr, val|
      if !param_blank?(val) && HistologyQuery::ALL_FLDS.include?("#{attr}")
        @where_select.push("sample_characteristics.#{attr}" + sql_condition(val)) if HistologyQuery::SCHAR_FLDS.include?("#{attr}")
        @where_select.push("samples.#{attr}" + sql_condition(val))                if HistologyQuery::SAMPLE_FLDS.include?("#{attr}")
        @where_values.push(sql_value(val))
      end
    end

    date_fld = 'histologies.he_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:histology_query], date_fld)
    return (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
  end

end