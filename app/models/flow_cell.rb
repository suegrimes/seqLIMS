# == Schema Information
#
# Table name: flow_cells
#
#  id              :integer          not null, primary key
#  flowcell_date   :date
#  nr_bases_read1  :string(4)
#  nr_bases_index  :string(2)
#  nr_bases_index1 :string(2)
#  nr_bases_index2 :string(2)
#  nr_bases_read2  :string(4)
#  cluster_kit     :string(10)
#  sequencing_kit  :string(10)
#  flowcell_status :string(2)
#  sequencing_key  :string(50)
#  run_description :string(80)
#  sequencing_date :date
#  seq_machine_id  :integer
#  seq_run_nr      :integer
#  machine_type    :string(10)
#  hiseq_xref      :string(50)
#  notes           :string(255)
#  created_at      :datetime
#  updated_at      :timestamp        not null
#

class FlowCell < ActiveRecord::Base
  belongs_to :seq_machine
  has_many :flow_lanes, :dependent => :destroy
  has_many :run_dirs,   :dependent => :destroy
  has_many :attached_files, :as => :sampleproc
  
  before_create :set_flowcell_status
  after_update :save_lanes
  
  validates_presence_of :machine_type, :nr_bases_read1
  validates_date :flowcell_date, :sequencing_date, :allow_blank => true
  
  scope :sequenced,   :conditions => "flowcell_status <> 'F'"
  scope :unsequenced, :conditions => "flowcell_status = 'F'"
  
  DEFAULT_MACHINE_TYPE = 'MiSeq'
  NR_LANES = {:MiSeq => 1, :NextSeq => 1, :GAIIx => 8, :HiSeq => 8}
  STATUS = %w{F R S Q N X}
  RUN_NR_TYPES = %w{LIMS Illumina}
  
  def for_publication?
    publication_flags = self.flow_lanes.collect{|flow_lane| flow_lane.for_publication?}
    return publication_flags.max
  end
  
  def publication_ids
    self.flow_lanes.collect{|flow_lane| flow_lane.publication_ids}.flatten.uniq
  end
  
  def sequenced?
    flowcell_status != 'F'
  end
  
  def flowcell_qc
    case flowcell_status
      when 'N' then 'N/A'
      when 'X' then 'Fail'
      else ' '
    end
  end
  
  def hiseq_qc?
    # This method is used to determine whether to display 'Synder' center QC fields, or 'SGTC'
    # If sequencing machine starts with 'S' or run# > 118, assume QC done at SGTC
    (machine_type == 'HiSeq' && (sequencing_key.split('_')[1][0].chr != 'S' && seq_run_nr < 110))
  end
  
  def hiseq_run?
    # This method is used to determine whether to display hiseq flowcell along with sequencing key
    (machine_type == 'HiSeq' && !hiseq_xref.blank? && hiseq_xref.split('_').size > 3)
  end
  
  def seq_run_key
    hiseq_flowcell = (hiseq_run? ? hiseq_xref.split('_')[3][0..5] : ' ')
    return (hiseq_run? ? [sequencing_key, ' (', hiseq_flowcell, ')'].join : sequencing_key)
  end
  
  def id_name
  (sequenced? ? "Run #: #{sequencing_key}" : "Flow Cell: #{id.to_s}")
  end

  def alt_run_or_descr
    alt_run = (hiseq_xref.blank? ? '' : ['Alt Run#: ', hiseq_xref].join)
    return (run_description.blank? ? alt_run : run_description)
  end
  
  def self.find_sequencing_runs(rptorder='runnr',condition_array=[])
    rpt_order = (rptorder == 'seqdt' ? 'flow_cells.sequencing_date DESC' : 'flow_cells.seq_run_nr DESC')
    self.sequenced.includes(:flow_lanes => :publications).where(sql_where(condition_array)).order(rpt_order).all
  end

  def self.find_for_export(flowcell_ids)
    self.includes(:flow_lanes => :publications).where("flow_cells.id IN (?)", flowcell_ids).all
  end
  
  def self.find_flowcells_for_sequencing
    self.unsequenced.includes(:flow_lanes => :publications).order("flow_cells.flowcell_date DESC").all
    #self.unsequenced.find(:all, :include => {:flow_lanes => :publications}, :order => 'flow_cells.flowcell_date DESC')
  end
  
  def self.getwith_attach(id)
    self.includes(:attached_files).find(id)
    #self.find(id, :include => :attached_files)
  end
  
  def self.find_flowcell_incl_rundirs(condition_array=[])
    self.includes(:run_dirs, {:flow_lanes => :publications}).where(sql_where(condition_array)).order('flow_cells.seq_run_nr, run_dirs.device_name').first
  end
  
  def set_flowcell_status(flowcell_status='F')
    self.flowcell_status = flowcell_status
  end
  
  def build_flow_lanes(lib_rows)
    lib_rows.each do |lrow|
      # Ignore blank lines (ie sequencing libraries which were not assigned to a lane)
      next if lrow[:lane_nr].blank?
      
      # Check for sequencing libraries assigned to multiple lanes, and replicate if needed
      # NextSeq is 4 identical lanes and only enter 1, so replicate 4 times
      lane_nrs = machine_type == 'NextSeq' ? [1,2,3,4] : lrow[:lane_nr].split(',')
      lane_nrs[0..(lane_nrs.size - 1)].each_with_index do |lnr, i|
        lrow[:lane_nr] = lnr
        lrow[:oligo_pool] = Pool.find(lrow[:pool_id]).tube_label if !lrow[:pool_id].blank?
        flow_lanes.build(lrow)
      end  
    end
  end
  
#  def new_lane_attributes=(lane_attributes)
#    # Remove blank lines (ie sequencing libraries which were not assigned to a lane)
#    lane_attributes.reject!{|attr| attr[:lane_nr].blank?}
#    
#    lane_attributes.each do |attributes|
#      # Check for sequencing libraries assigned to multiple lanes, and replicate if needed
#      lane_nrs = attributes[:lane_nr].split(',')
#      lane_nrs[0..(lane_nrs.size - 1)].each do |lnr|
#        attributes[:lane_nr] = lnr
#        flow_lanes.build(attributes)
#      end
#    end
#  end
  
  def existing_lane_attributes=(lane_attributes)
    flow_lanes.reject(&:new_record?).each do |flow_lane|
      upd_attributes = lane_attributes[flow_lane.id.to_s]
      if upd_attributes
        upd_attributes[:oligo_pool] = (upd_attributes[:pool_id].blank? ? '' : Pool.find(upd_attributes[:pool_id]).tube_label)
        flow_lane.attributes = upd_attributes
      else
        flow_lanes.delete(flow_lane)
      end
    end
  end
  
  def save_lanes
    flow_lanes.each do |flow_lane|
      flow_lane.save(:validate=>false) unless flow_lane.lane_nr.nil? || flow_lane.lane_nr.blank?
    end
  end
  
  
end
