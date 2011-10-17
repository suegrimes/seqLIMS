# == Schema Information
#
# Table name: seq_libs
#
#  id                  :integer(4)      not null, primary key
#  barcode_key         :string(20)
#  lib_name            :string(50)      default(""), not null
#  library_type        :string(2)
#  lib_status          :string(2)
#  protocol_id         :integer(4)
#  owner               :string(25)
#  preparation_date    :date
#  runtype_adapter     :string(25)
#  target_pool         :string(50)
#  enzyme_code         :string(50)
#  alignment_ref_id    :integer(4)
#  alignment_ref       :string(50)
#  trim_bases          :integer(2)
#  sample_conc         :decimal(15, 9)
#  sample_conc_uom     :string(10)
#  lib_conc_requested  :decimal(15, 9)
#  lib_conc_uom        :string(10)
#  notebook_ref        :string(50)
#  notes               :string(255)
#  quantitation_method :string(20)
#  starting_amt_ng     :decimal(11, 3)
#  pcr_size            :integer(2)
#  dilution            :decimal(6, 3)
#  updated_by          :integer(2)
#  created_at          :datetime
#  updated_at          :timestamp       not null
#

class SeqLib < ActiveRecord::Base
  
  has_many :lib_samples, :dependent => :destroy
  has_many :flow_lanes
  has_many :align_qc, :through => :flow_lanes
  has_many :attached_files, :as => :sampleproc
  
  accepts_nested_attributes_for :lib_samples
  
  validates_presence_of :barcode_key, :lib_name, :owner, :runtype_adapter, :alignment_ref
  validates_uniqueness_of :barcode_key, :message => 'is not unique'
  validates_date :preparation_date
  #validates_numericality_of :trim_bases, :allow_blank => true
  validates_format_of :trim_bases, :with => /^\d+$/, :allow_blank => true, :message => "# bases to trim must be an integer"
  
  before_create :set_default_values
  #after_update :save_samples
  
  MULTIPLEX_SAMPLES = 16
  MILLUMINA_SAMPLES = 12
  SAMPLE_CONC = ['ng/ul', 'nM']
  BASE_GRAMS_PER_MOL = 660
  
  def validate
    if self.new_record?
      if !barcode_key.nil?
        errors.add(:barcode_key, "must start with 'L'") if barcode_key[0,1] != 'L'
      end
      errors.add(:pcr_size,    "must be entered")     if pcr_size.blank?
      errors.add(:sample_conc, "must be entered")     if sample_conc.blank?
      errors.add(:sample_conc, "cannot be > 10nM")    if (!sample_conc.nil? && sample_conc_uom == 'nM' && sample_conc > 10) 
    elsif !barcode_key.nil?
      errors.add(:barcode_key, "must start with 'L'") if !['L','X'].include?(barcode_key[0,1])
    end
    
    if barcode_key.size > 0
      if barcode_key.size == 1 || barcode_key[1..-1].scan(/\D/).size > 0
        errors.add(:barcode_key, "must be numeric after the 'L'") 
      end
    end
  end
  
  def owner_abbrev
    if owner.nil? || owner.length < 11
      owner1 = owner
    else
      first_and_last = owner.split(' ')
      owner1 = [first_and_last[0], first_and_last[1][0,1]].join(' ')
    end
    return owner1
  end
  
  def dummy_barcode
    (barcode_key[0,1] == 'X' ? true : false)
  end
  
  def lib_barcode
    (dummy_barcode == true ? 'n/a' : barcode_key)
  end
  
  def multiplexed?
    (library_type == 'M')
  end
  
  def control_lane_nr
    (lib_status == 'C'? 4 : nil)
  end
  
  def sample_conc_with_uom
    conc = (sample_conc ? number_with_precision(sample_conc, :precision => 2) : '--')
    return [conc, sample_conc_uom].join(' ')
  end
  
  def sample_conc_nm
    if sample_conc_uom == 'nM'
      return sample_conc
    elsif pcr_size.nil?  # pcr_size was not always a required field; if not entered cannot convert ng/ul to nM
      return nil          
    elsif sample_conc_uom == 'ng/ul'         #convert from ng/ul to nM
      return (sample_conc  / (pcr_size * BASE_GRAMS_PER_MOL) * 1000000)
    else
      return sample_conc
    end
  end
  
  def sample_conc_ngul
    # conversion from nM to ng/ul is: (sample_conc * (pcr_size * BASE_GRAMS_PER_MOL) / 1000000)
    return (sample_conc_uom == 'ng/ul'? sample_conc : nil)
  end
  
  def set_default_values
    self.lib_status = 'L'
    self.lib_conc_uom = 'pM'
    self.sample_conc_uom = 'ng/ul'
  end
  
  def self.find_for_query(condition_array)
    self.find(:all, :select => "seq_libs.*, COUNT(DISTINCT(flow_cells.id)) AS 'seq_run_cnt', COUNT(flow_lanes.id) as 'seq_lane_cnt'",
                    :joins => "LEFT JOIN flow_lanes ON flow_lanes.seq_lib_id = seq_libs.id 
                               LEFT JOIN flow_cells ON flow_lanes.flow_cell_id = flow_cells.id",
                    :group => "seq_libs.id",
                    :conditions => condition_array)
  end
  
  def self.find_for_export(id)
    self.find(id, :include => {:flow_lanes => [:flow_cell, :align_qc]},
                  :conditions => "flow_cells.flowcell_status <> 'F'")
  end
  
  def self.unique_projects
    self.find(:all, :select => 'DISTINCT project', :order => 'project')
  end
  
  def self.getwith_attach(id)
    self.find(id, :include => :attached_files)
  end
  
  def self.upd_lib_status(flow_cell, lib_status)
    flow_lanes = FlowLane.find_all_by_flow_cell_id(flow_cell.id)
    flow_lanes.each do |lane|
      self.update(lane.seq_lib_id, :lib_status => lib_status) if lane.seq_lib.lib_status != 'C'
    end
  end
  
#  # As of Rails 2.3, can delete methods below and use nested attributes for lib_samples?
#  def new_sample_attributes=(sample_attributes)
#    sample_attributes.each do |attributes|
#      lib_samples.build(attributes) unless attributes[:sample_name].blank?
#    end
#  end
#  
#  def existing_sample_attributes=(sample_attributes)
#    lib_samples.reject(&:new_record?).each do |lib_sample|
#      upd_attributes = sample_attributes[lib_sample.id.to_s]
#      if upd_attributes
#        lib_sample.attributes = upd_attributes
#      else
#        lib_samples.delete(lib_sample)
#      end
#    end
#  end
#  
#  def save_samples
#    lib_samples.each do |lib_sample|
#      lib_sample.save(false)  
#    end
#  end
#  
end
