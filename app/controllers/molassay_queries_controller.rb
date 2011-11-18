class MolassayQueriesController < ApplicationController
  authorize_resource :class => MolecularAssay
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query
    @molassay_query = MolassayQuery.new(:to_date   =>  Date.today)
  end
  
   def index
    @molassay_query = MolassayQuery.new(params[:molassay_query]) 
     
    if @molassay_query.valid?
      condition_array = define_conditions(params)
      @molecular_assays = MolecularAssay.find_for_query(condition_array)                                       
      render :action => :index
    else
      dropdowns
      render :action => :new_query
    end
    #render :action => 'debug'
  end
  
protected
  def dropdowns
    @owners       = Researcher.populate_dropdown('all')
  end
  
  def define_conditions(params)
    @where_select = []; @where_values = [];
    
    if !param_blank?(params[:molassay_query][:patient_id])
      @where_select.push('processed_samples.patient_id = ?')
      @where_values.push(params[:molassay_query][:patient_id])
    end
    
    if !param_blank?(params[:molassay_query][:owner])
      @where_select.push('molecular_assays.owner IN (?)')
      @where_values.push(params[:molassay_query][:owner])
    end
    
    date_fld = 'molecular_assays.preparation_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:molassay_query], date_fld)
    
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end
  
 end