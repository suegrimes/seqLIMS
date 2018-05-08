# == Schema Information
#
# Table name: align_qc
#
#  id                       :integer          not null, primary key
#  flow_lane_id             :integer          not null
#  sequencing_key           :string(50)
#  lane_nr                  :integer
#  lane_yield               :integer
#  clusters_raw             :integer
#  clusters_pf              :integer
#  cycle1_intensity_pf      :integer
#  cycle20_intensity_pct_pf :integer
#  pct_pf_clusters          :decimal(6, 2)
#  pct_align_pf             :decimal(6, 2)
#  align_score_pf           :decimal(8, 2)
#  pct_error_rate_pf        :decimal(6, 2)
#  nr_NM                    :integer
#  nr_QC                    :integer
#  nr_RX                    :integer
#  nr_U0                    :integer
#  nr_U1                    :integer
#  nr_U2                    :integer
#  nr_UM                    :integer
#  nr_nonuniques            :integer
#  nr_uniques               :integer
#  min_insert               :integer
#  max_insert               :integer
#  median_insert            :integer
#  total_reads              :integer
#  pf_reads                 :integer
#  failed_reads             :integer
#  total_errors             :integer
#  consistent_unique_bp     :integer
#  consistent_unique_pct    :decimal(4, 1)
#  rescued_bp               :integer
#  rescued_pct              :decimal(4, 1)
#  total_consistent_bp      :integer
#  total_consistent_pct     :decimal(4, 1)
#  pf_unique_bp             :integer
#  pf_unique_pct            :decimal(4, 1)
#  notes                    :string(255)
#  created_at               :datetime
#  updated_at               :timestamp
#

class AlignQc < ActiveRecord::Base
  self.table_name = 'align_qc'
  
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
