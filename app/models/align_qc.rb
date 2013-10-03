# == Schema Information
#
# Table name: align_qc
#
#  id                       :integer(4)      not null, primary key
#  flow_lane_id             :integer(4)      not null
#  sequencing_key           :string(50)
#  lane_nr                  :integer(1)
#  lane_yield               :integer(4)
#  clusters_raw             :integer(4)
#  clusters_pf              :integer(4)
#  cycle1_intensity_pf      :integer(4)
#  cycle20_intensity_pct_pf :integer(4)
#  pct_pf_clusters          :decimal(6, 2)
#  pct_align_pf             :decimal(6, 2)
#  align_score_pf           :decimal(8, 2)
#  pct_error_rate_pf        :decimal(6, 2)
#  nr_NM                    :integer(4)
#  nr_QC                    :integer(4)
#  nr_RX                    :integer(4)
#  nr_U0                    :integer(4)
#  nr_U1                    :integer(4)
#  nr_U2                    :integer(4)
#  nr_UM                    :integer(4)
#  nr_nonuniques            :integer(4)
#  nr_uniques               :integer(4)
#  min_insert               :integer(2)
#  max_insert               :integer(2)
#  median_insert            :integer(2)
#  total_reads              :integer(4)
#  pf_reads                 :integer(4)
#  failed_reads             :integer(4)
#  consistent_unique_bp     :integer(4)
#  consistent_unique_pct    :decimal(4, 1)
#  rescued_bp               :integer(4)
#  rescued_pct              :decimal(4, 1)
#  total_consistent_bp      :integer(4)
#  total_consistent_pct     :decimal(4, 1)
#  pf_unique_bp             :integer(4)
#  pf_unique_pct            :decimal(4, 1)
#  notes                    :string(255)
#  created_at               :datetime
#  updated_at               :timestamp
#

class AlignQc < ActiveRecord::Base
  set_table_name 'align_qc'
  
  belongs_to :flow_lane
  
  validates_numericality_of :cycle20_intensity_pct_pf, :pct_pf_clusters, :align_score_pf, :pct_align_pf, :pct_error_rate_pf, :allow_blank => true
  validates_numericality_of :clusters_raw, :clusters_pf, :cycle1_intensity_pf, :nr_NM, :nr_QC, :nr_RX, :nr_U0, :nr_U1, :nr_U2, :nr_UM,
                            :only_integer => true, :allow_blank => true, :message => 'must be an integer'
  
  before_update :calc_pct_align

  def calc_pct_align
    if flow_lane.flow_cell.machine_type == 'MiSeq' && !nr_uniques.nil? && nr_uniques > 0 
      self.pct_error_rate_pf = total_errors * 100 / (nr_uniques * flow_lane.flow_cell.nr_bases_read1.to_i) 
      self.pct_align_pf      = nr_uniques * 100 / (nr_uniques + nr_nonuniques)
    end
  end
  
  def self.add_qc_for_flow_cell(flow_cell_id)
    qc_added = 0
    flow_lanes = FlowLane.find_all_by_flow_cell_id(flow_cell_id)
    flow_lanes.each do |flow_lane|
      align_qc = AlignQc.find_or_initialize_by_flow_lane_id_and_lane_nr_and_sequencing_key(flow_lane.id, flow_lane.lane_nr, flow_lane.sequencing_key)
      if align_qc.new_record?
        qc_added +=1 if align_qc.save
      end
    end
    FlowCell.update(flow_cell_id, :flowcell_status => 'Q') if qc_added > 0
    return qc_added
  end
  
end
