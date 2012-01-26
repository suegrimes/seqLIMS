class SeqlibLanesController < ApplicationController
  
  def show
    authorize! :read, SeqLib
    @seq_lib = SeqLib.find_by_id(params[:id], :include => {:flow_lanes => [:flow_cell, :align_qc]},
                                 :conditions => "flow_cells.flowcell_status <> 'F'")
    @lib_lanes_by_seq_type = @seq_lib.flow_lanes.group_by {|flow_lane| flow_lane.machine_type}
    #render :action => 'debug
  end
  
  def export_libqc
    export_type = 'T'
    @seq_lib = SeqLib.find_for_export(params[:id])
    file_basename = ['LIMS_SeqLibQC', Date.today.to_s].join("_")
    
    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_libqc_csv(@seq_lib)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')
                  
      when 'S'  # Display text to screen (for development/testing)
        csv_string = export_libqc_csv(@seq_lib)
        render :text => csv_string
      
      else # Use for debugging
        render :debug
    end
  end

  
protected
  def export_libqc_csv(seq_lib)    
    hdgs, flds = export_libqc_setup
    
    csv_string = FasterCSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs
      
      seq_lib.flow_lanes.each do |flow_lane|
        model_xref = {:sl => seq_lib, :fc => flow_lane.flow_cell, :fl => flow_lane, :aq => flow_lane.align_qc}
        fld_array    = []
        
        flds.each do |obj_code, fld|
          obj = (model_xref[obj_code.to_sym] ||= nil)   
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
  
  def export_libqc_setup
    hdgs  = (%w{DownloadDt LibID LibBarcode LibName SeqKey HiSeqRef FlowCellDt ClusterKit SequencingKit Lane 
                Clusters(Raw) Clusters(PF) Cycle1_Int Cycle20_Int% Align%(PF) Error%(PF) Unique NonUnique
                MedianInsert TotalReads PF_Reads ConsistentUnique Rescued TotalConsistent PF_Unique})
    
    flds  = [['sl', 'id'],
             ['sl', 'lib_barcode'],
             ['sl', 'lib_name'],
             ['fl', 'sequencing_key'],
             ['fc', 'hiseq_xref'],
             ['fc', 'flowcell_date'],
             ['fc', 'cluster_kit'],
             ['fc', 'sequencing_kit'],
             ['fl', 'lane_nr'],
             ['aq', 'clusters_raw'],
             ['aq', 'clusters_pf'],
             ['aq', 'cycle1_intensity_pf'],
             ['aq', 'cycle20_intensity_pct_pf'],
             ['aq', 'pct_align_pf'], 
             ['aq', 'pct_error_rate_pf'],
             ['aq', 'nr_uniques'],
             ['aq', 'nr_nonuniques'],
             ['aq', 'median_insert'],
             ['aq', 'total_reads'],
             ['aq', 'pf_reads'],
             ['aq', 'consistent_unique_bp'],
             ['aq', 'rescued_bp'],
             ['aq', 'total_consistent_bp'],
             ['aq', 'pf_unique_bp']]
            
    return hdgs, flds
  end
  
end
