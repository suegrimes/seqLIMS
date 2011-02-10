# == Schema Information
#
# Table name: flow_lanes
#
#  id               :integer(4)      not null, primary key
#  flow_cell_id     :integer(4)      not null
#  seq_lib_id       :integer(4)
#  sequencing_key   :string(50)
#  sequencer_type   :string(2)
#  lib_barcode      :string(20)
#  lib_name         :string(50)
#  lane_nr          :integer(1)      not null
#  lib_conc         :float(11)
#  lib_conc_uom     :string(6)
#  runtype_adapter  :string(20)
#  alignment_ref_id :integer(4)
#  alignment_ref    :string(50)
#  notes            :string(255)
#  created_at       :datetime
#  updated_at       :timestamp
#

class FlowLane < ActiveRecord::Base
  
  belongs_to :flow_cell
  belongs_to :seq_lib
  has_one    :align_qc
  
  validates_numericality_of :lane_nr, :only_integer => true
  validates_inclusion_of :lane_nr, :in => 1..8,
                         :message => "must be integer between 1 and 8"
  
  def self.upd_seq_key(flow_cell)
    cell_attrs = {:sequencing_key => flow_cell.sequencing_key,
                  :sequencer_type => flow_cell.sequencer_type}
    flow_lanes = self.find_all_by_flow_cell_id(flow_cell.id)
    self.upd_multi_lanes(flow_lanes, cell_attrs) if flow_lanes
  end

  # upd_lib_lanes
  # When sequencing library attributes are updated, this method is called to update
  # sequencing library information for any flow cell lanes which reference that library
  def self.upd_lib_lanes(seq_lib)
    # set up hash of sequencing library attributes for this library
    lib_attrs  = {:lib_barcode      => seq_lib.lib_barcode,
                  :lib_name         => seq_lib.lib_name,
                  :runtype_adapter  => seq_lib.runtype_adapter,
                  :alignment_ref_id => seq_lib.alignment_ref_id,
                  :alignment_ref    => seq_lib.alignment_ref}
                  
    # Find all flow lanes which reference the above sequencing library, and perform update
    flow_lanes = self.find_all_by_seq_lib_id(seq_lib.id)            
    self.upd_multi_lanes(flow_lanes, lib_attrs) if flow_lanes
  end
  
  def self.upd_multi_lanes(flow_lanes, attrs)
    # Set up arrays of ids, and of attribute values, for SQL update
    lane_ids   = flow_lanes.collect {|lane| lane.id} if flow_lanes
    lane_attrs = []
    lane_ids.each_with_index {|lane_id, i| lane_attrs[i] = attrs} if lane_ids
    self.update(lane_ids, lane_attrs) if lane_ids    
  end
end
