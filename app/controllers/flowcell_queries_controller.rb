class FlowcellQueriesController < ApplicationController
  authorize_resource :class => FlowCell
  
  before_filter :dropdowns, :only => :new_query
  
  def new_query
    @flowcell_query = FlowcellQuery.new(:from_date => (Date.today - 6.months).beginning_of_month,
                                        :to_date   =>  Date.today)
  end
 
  def index
    @flowcell_query = FlowcellQuery.new(params[:flowcell_query])
    
    if @flowcell_query.valid?
      @condition_array = define_conditions(params)
      @hdr = 'Sequencing Runs (Filtered)'
      @flow_cells = FlowCell.find_sequencing_runs(SEQ_ORDER, sql_where(@condition_array))
      if @flow_cells.size == 1 
        @flow_cell = @flow_cells[0]
        redirect_to :controller => 'flow_cells', :action => :show, :id => @flow_cell.id
      else
        render :action => :index
      end
      
    else
      dropdowns
      render :action => :new_query
    end
  end

  def export_seqruns
    export_type = 'T'
    @flow_cells = FlowCell.find_for_export(params[:export_id])
    file_basename = ['LIMS_SeqRuns', Date.today.to_s].join("_")

    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_samples_csv(@flow_cells)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')

      else # Use for debugging
        csv_string = export_samples_csv(@flow_cells)
        render :text => csv_string
    end
  end

protected
  def dropdowns
    @machine_types = Category.populate_dropdown_for_category('machine type')
  end
  
  def define_conditions(params)
    @where_select = []
    @where_values = []
    
    if !params[:flowcell_query][:run_nr].blank?
      run_nr_i = params[:flowcell_query][:run_nr].to_i
      if params[:flowcell_query][:run_nr_type] == 'LIMS'
        sql_where_clause = ["flow_cells.seq_run_nr = ?", run_nr_i]
      else
        run_nr_string = run_nr_i.to_s.rjust(4,"0")
        sql_where_clause = ["flow_cells.hiseq_xref LIKE ?", "%_#{run_nr_string}_%"]
      end
      
    else
      if !param_blank?(params[:flowcell_query][:machine_type])
        @where_select.push("flow_cells.machine_type = ?")
        @where_values.push(params[:flowcell_query][:machine_type])
      end
      
      date_fld = 'flow_cells.sequencing_date'
      @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:flowcell_query], date_fld)
      sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    end
    
    return sql_where_clause
  end

  def export_samples_csv(flow_cells)
    hdgs, flds = export_samples_setup

    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs

      flow_cells.each do |flow_cell|
        fld_array    = []
        flowcell_xref  = model_xref(flow_cell)

        flds.each do |obj_code, fld|
          obj = flowcell_xref[obj_code.to_sym]
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
    hdgs  = %w{DownloadDt RunNr AltRun ClusterKit SequencingKit Read1 Index1 Index2 Read2 Publication? Description Notes}

    flds  = [['fc', 'seq_run_key'],
             ['fc', 'hiseq_xref'],
             ['fc', 'cluster_kit'],
             ['fc', 'sequencing_kit'],
             ['fc', 'nr_bases_read1'],
             ['fc', 'nr_bases_index1'],
             ['fc', 'nr_bases_index2'],
             ['fc', 'nr_bases_read2'],
             ['fc', 'for_publication?'],
             ['fc', 'run_description'],
             ['fc', 'notes']]

    return hdgs, flds
  end

  def model_xref(flow_cell)
    flowcell_xref = {:fc => flow_cell}
  end
  
end