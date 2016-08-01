# == Schema Information
#
# Table name: lane_metrics
#
#  id                       :integer          not null, primary key
#  flow_lane_id             :integer          not null
#  lane_nr                  :integer
#  density_kmm2
#  clusters_pf_pct
#  reads_M
#  reads_pf_M
#  q30_pct
#  r1_phix_align_pct
#  r1_error_pct
#  r1_intensity_cycle1
#  r2_phix_align_pct
#  r2_error_pct
#  r2_intensity_cycle1
#  updated_at               :timestamp
#

class LaneMetric < ActiveRecord::Base
  belongs_to :flow_lane
end
