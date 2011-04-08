# == Schema Information
#
# Table name: flow_cells
#
#  id              :integer(4)      not null, primary key
#  flowcell_date   :date
#  nr_bases_read1  :string(4)
#  nr_bases_index  :string(2)
#  nr_bases_read2  :string(4)
#  cluster_kit     :string(10)
#  sequencing_kit  :string(10)
#  flowcell_status :string(2)
#  sequencing_key  :string(50)
#  sequencing_date :date
#  seq_machine_id  :integer(4)
#  seq_run_nr      :integer(2)
#  sequencer_type  :string(2)
#  hiseq_xref      :string(50)
#  notes           :string(255)
#  created_at      :datetime
#  updated_at      :timestamp       not null
#

class FlowCell < ActiveRecord::Base
  has_many :flow_lanes, :dependent => :destroy
  has_many :run_dirs,   :dependent => :destroy
  has_many :attached_files, :as => :sampleproc
  
  before_create :set_flowcell_status
  after_update :save_lanes
  
  validates_presence_of :nr_bases_read1
  validates_date :flowcell_date, :sequencing_date, :allow_blank => true
  
  named_scope :sequenced,   :conditions => "flowcell_status <> 'F'"
  named_scope :unsequenced, :conditions => "flowcell_status = 'F'"
  
  NR_LANES = 8
  STATUS = %w{F R S Q N}
  
  def sequenced?
    flowcell_status != 'F'
  end
  
  def seq_run_key
    hiseq_flowcell = (hiseq_xref.blank? ? '' : hiseq_xref.split('_')[3][0..5])
    (hiseq_xref.blank? ? sequencing_key : [sequencing_key,  ' (', hiseq_flowcell, ')'].join)
  end
  
  def id_name
  (sequenced? ? "Sequencing Run: #{sequencing_key}" : "Flow Cell: #{id.to_s}")
  end
  
  def self.find_sequencing_runs(condition_array=[])
    self.sequenced.find(:all, :order => 'flow_cells.seq_run_nr DESC',
                        :conditions => condition_array)
  end
  
  def self.find_flowcells_for_sequencing
    self.unsequenced.find(:all, :order => 'flow_cells.flowcell_date DESC')
  end
  
  def self.getwith_attach(id)
    self.find(id, :include => :attached_files)
  end
  
  def self.find_flowcell_incl_rundirs(condition_array=nil)
    self.find(:first, :include => :run_dirs,
                      :order => "flow_cells.seq_run_nr, run_dirs.device_name",
                      :conditions => condition_array)
  end
  
  def set_flowcell_status(flowcell_status='F')
    self.flowcell_status = flowcell_status
  end
  
  def build_flow_lanes(lanes)
    lanes.reject!{|lane| lane[:lane_nr].blank?}
    
    lanes.each do |lane|
      lane_nrs = lane[:lane_nr].split(',')
      lane_nrs[0..(lane_nrs.size - 1)].each_with_index do |lnr, i|
        lane[:lane_nr] = lnr
        flow_lanes.build(lane)
      end  
    end
  end
  
  
  def new_lane_attributes=(lane_attributes)
    # Remove blank lines (ie sequencing libraries which were not assigned to a lane)
    lane_attributes.reject!{|attr| attr[:lane_nr].blank?}
    
    lane_attributes.each do |attributes|
      # Check for sequencing libraries assigned to multiple lanes, and replicate if needed
      lane_nrs = attributes[:lane_nr].split(',')
      lane_nrs[0..(lane_nrs.size - 1)].each do |lnr|
        attributes[:lane_nr] = lnr
        flow_lanes.build(attributes)
      end
    end
  end
  
  def existing_lane_attributes=(lane_attributes)
    flow_lanes.reject(&:new_record?).each do |flow_lane|
      upd_attributes = lane_attributes[flow_lane.id.to_s]
      if upd_attributes
        flow_lane.attributes = upd_attributes
      else
        flow_lanes.delete(flow_lane)
      end
    end
  end
  
  def save_lanes
    flow_lanes.each do |flow_lane|
      flow_lane.save(false) unless flow_lane.lane_nr.nil? || flow_lane.lane_nr.blank?
    end
  end
  
  
end
