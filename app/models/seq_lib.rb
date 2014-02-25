# == Schema Information
#
# Table name: seq_libs
#
#  id                  :integer          not null, primary key
#  barcode_key         :string(20)
#  lib_name            :string(50)       default(""), not null
#  library_type        :string(2)
#  lib_status          :string(2)
#  protocol_id         :integer
#  owner               :string(25)
#  preparation_date    :date
#  runtype_adapter     :string(25)
#  project             :string(50)
#  pool_id             :integer
#  oligo_pool          :string(8)
#  alignment_ref_id    :integer
#  alignment_ref       :string(50)
#  trim_bases          :integer
#  sample_conc         :decimal(15, 9)
#  sample_conc_uom     :string(10)
#  lib_conc_requested  :decimal(15, 9)
#  lib_conc_uom        :string(10)
#  notebook_ref        :string(50)
#  notes               :string(255)
#  quantitation_method :string(20)
#  starting_amt_ng     :decimal(11, 3)
#  pcr_size            :integer
#  dilution            :decimal(6, 3)
#  updated_by          :integer
#  created_at          :datetime
#  updated_at          :timestamp        not null
#

class SeqLib < ActiveRecord::Base
  
  belongs_to :user, :foreign_key => :updated_by
  has_many :lib_samples, :dependent => :destroy
  has_many :mlib_samples, :class_name => 'LibSample', :foreign_key => :splex_lib_id
  has_many :flow_lanes
  has_many :align_qc, :through => :flow_lanes
  has_many :processed_samples, :through => :lib_samples
  has_many :attached_files, :as => :sampleproc
  
  accepts_nested_attributes_for :lib_samples
  
  validates_uniqueness_of :barcode_key, :message => 'is not unique'
  validates_date :preparation_date
  #validates_numericality_of :trim_bases, :allow_blank => true
  validates_format_of :trim_bases, :with => /^\d+$/, :allow_blank => true, :message => "# bases to trim must be an integer"
  
  before_create :set_default_values
  #after_update :upd_mplex_pool, :if => Proc.new { |lib| lib.oligo_pool_changed? }
  #after_update :save_samples
  
  BARCODE_PREFIX = 'L'
  MULTIPLEX_SAMPLES = 16
  MILLUMINA_SAMPLES = 12
  SAMPLE_CONC = ['ng/ul', 'nM']
  BASE_GRAMS_PER_MOL = 660
  
  def validate
    if self.new_record?
      if !barcode_key.nil?
        errors.add(:barcode_key, "must start with '#{BARCODE_PREFIX}'") if barcode_key[0,1] != BARCODE_PREFIX
      end
      errors.add(:pcr_size,    "must be entered")     if pcr_size.blank?
      errors.add(:sample_conc, "must be entered")     if sample_conc.blank?  
    elsif !barcode_key.nil?
      errors.add(:barcode_key, "must start with '#{BARCODE_PREFIX}'") if ![BARCODE_PREFIX,'X'].include?(barcode_key[0,1])
    end
    
    if barcode_key.size > 0
      if barcode_key.size == 1 || barcode_key[1..-1].scan(/\D/).size > 0
        errors.add(:barcode_key, "must be numeric after the '#{BARCODE_PREFIX}'") 
      end
    end
    
    errors.add(:sample_conc, "cannot be > 10nM")    if (!sample_conc.nil? && sample_conc_uom == 'nM' && sample_conc > 10)    
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

  def patient_ids
    patient_ids = lib_samples.collect{|lib_sample| lib_sample.patient_id}
    return (patient_ids.compact.size > 0 ? patient_ids.uniq.compact.join(' ,') : nil)
  end
  
  def dummy_barcode
    (barcode_key[0,1] == 'X' ? true : false)
  end
  
  def lib_barcode
    (dummy_barcode == true ? 'N/A' : barcode_key)
  end
  
  def multiplex_lib?
    (library_type == 'M')
  end
  
  def in_multiplex_lib?
    !mlib_samples.nil?
  end
  
  def on_flow_lane?
    !flow_lanes.nil?
  end

  def flow_lane_ct
    flow_lanes.size
  end
  
  def control_lane?
    (lib_status == 'C')
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
    elsif pcr_size.nil? || sample_conc.nil?  # pcr_size was not always a required field; if not entered cannot convert ng/ul to nM
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
    self.select("seq_libs.*, COUNT(DISTINCT(flow_cells.id)) AS 'seq_run_cnt', COUNT(flow_lanes.id) AS 'seq_lane_cnt', " +
                    "COUNT(align_qc.id) AS 'qc_lane_cnt'")
        .joins('LEFT JOIN flow_lanes ON flow_lanes.seq_lib_id = seq_libs.id
              LEFT JOIN align_qc ON align_qc.flow_lane_id = flow_lanes.id
              LEFT JOIN flow_cells ON flow_lanes.flow_cell_id = flow_cells.id').where(sql_where(condition_array)).group('seq_libs.id')
    #self.find(:all, :select => "seq_libs.*, COUNT(DISTINCT(flow_cells.id)) AS 'seq_run_cnt', COUNT(flow_lanes.id) AS 'seq_lane_cnt', " +
    #                           "COUNT(align_qc.id) AS 'qc_lane_cnt'",
    #                :joins => "LEFT JOIN flow_lanes ON flow_lanes.seq_lib_id = seq_libs.id
     #                          LEFT JOIN align_qc ON align_qc.flow_lane_id = flow_lanes.id
     #                          LEFT JOIN flow_cells ON flow_lanes.flow_cell_id = flow_cells.id",
    #                :group => "seq_libs.id",
     #               :conditions => condition_array)
  end
  
  def self.find_for_export(id)
    self.find(id).includes(:flow_lanes => [:flow_cell, :align_qc]).where("flow_cells.flowcell_status <> 'F'")
    #self.find(id, :include => {:flow_lanes => [:flow_cell, :align_qc]},
    #              :conditions => "flow_cells.flowcell_status <> 'F'")
  end

  def self.find_all_for_export(seqlib_ids)
    self.includes(:flow_lanes, :processed_samples).where("seq_libs.id IN (?)", seqlib_ids).all
  end
  
  def self.unique_projects
    self.select(:project).order(:project).uniq
    #self.find(:all, :select => 'DISTINCT project', :order => 'project')
  end
  
  def self.getwith_attach(id)
    self.includes(:attached_files).find(id)
  end
  
  def self.upd_lib_status(flow_cell, lib_status)
    flow_lanes = FlowLane.find_all_by_flow_cell_id(flow_cell.id)
    flow_lanes.each do |lane|
      self.update(lane.seq_lib_id, :lib_status => lib_status) if lane.seq_lib.lib_status != 'C'
    end
  end
  
  def self.upd_mplex_splex(splex_lib)
    # Find all cases where supplied sequencing library is one of the 'samples' in a multiplex library
    lib_samples = LibSample.find_all_by_splex_lib_id(splex_lib.id)
    
    # If any cases found, collect all the multiplex libraries and their associated 'samples'(=singleplex libs)
    if !lib_samples.nil?
      mplex_ids  = lib_samples.collect(&:seq_lib_id)
      mplex_libs = self.find_all_by_id(mplex_ids, :include => {:lib_samples => :splex_lib})
      
      mplex_libs.each do |lib|
        self.upd_mplex_fields(lib)
      end
    end
  end
  
  def self.upd_mplex_fields(mplex_lib)
    # Determine if all pools for associated samples are the same, if so, update multiplex pool accordingly
    # Determine if all adapters for associated samples are the same, if so, update adapter accordingly
    slib_pools = mplex_lib.lib_samples.collect{|lsamp| [lsamp.splex_lib.pool_id, (lsamp.splex_lib.oligo_pool ? lsamp.splex_lib.oligo_pool : '')]}
    slib_adapters = mplex_lib.lib_samples.collect{|lsamp| lsamp.splex_lib.runtype_adapter}
        
    if slib_pools.uniq.size > 1 
      self.update(mplex_lib.id, :oligo_pool => 'Multiple')
    else
      self.update(mplex_lib.id, :pool_id => slib_pools[0][0], :oligo_pool => slib_pools[0][1])
    end
        
    if slib_adapters.uniq.size > 1
      self.update(mplex_lib.id, :runtype_adapter => 'Multiple')
    else
      self.update(mplex_lib.id, :runtype_adapter => slib_adapters[0])
    end
  end
 
end
