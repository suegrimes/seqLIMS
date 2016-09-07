# == Schema Information
#
# Table name: seq_libs
#
#  id                  :integer          not null, primary key
#  barcode_key         :string(20)
#  lib_name            :string(50)       not null
#  library_type        :string(2)
#  lib_status          :string(2)
#  protocol_id         :integer
#  owner               :string(25)
#  preparation_date    :date
#  adapter_id          :integer
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
require 'rubyXL'

class SeqLib < ActiveRecord::Base
  
  belongs_to :user, :foreign_key => :updated_by
  belongs_to :adapter
  has_many :lib_samples, :dependent => :destroy
  has_many :mlib_samples, :class_name => 'LibSample', :foreign_key => :splex_lib_id
  has_many :flow_lanes
  has_many :align_qc, :through => :flow_lanes
  has_many :processed_samples, :through => :lib_samples
  has_many :attached_files, :as => :sampleproc
  
  accepts_nested_attributes_for :lib_samples
  
  validates_uniqueness_of :barcode_key, :message => 'is not unique'
  validates_format_of :barcode_key, :with => /^\w\d{6}$/, :message => "must be 6 digit integer after 'L' prefix"
  validates_date :preparation_date
  validates_format_of :trim_bases, :with => /^\d+$/, :allow_blank => true, :message => "# bases to trim must be an integer"
  validates_numericality_of :pcr_size, :only_integer => true, :greater_than => 20, :on => :create, :message => "is not a valid integer >20"
  validates_numericality_of :sample_conc, :greater_than_or_equal_to => 10, :on => :create, :if => "sample_conc_uom == 'nM'",
                            :message => "must be >= 10nM"

  validate :barcode_prefix_valid
  
  before_create :set_default_values
  #after_update :upd_mplex_pool, :if => Proc.new { |lib| lib.oligo_pool_changed? }
  #after_update :save_samples
  
  BARCODE_PREFIX = 'L'
  SAMPLE_CONC = ['nM', 'ng/ul']
  BASE_GRAMS_PER_MOL = 660
  
  def barcode_prefix_valid
    valid_prefix = [BARCODE_PREFIX]
    valid_prefix.push('X') if !self.new_record?
    if !barcode_key.nil?
      errors.add(:barcode_key, "must start with '#{BARCODE_PREFIX}'") if !valid_prefix.include?(barcode_key[0,1])
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

  def patient_ids
    patient_ids = lib_samples.collect{|lib_sample| lib_sample.patient_id}
    return (patient_ids.compact.size > 0 ? patient_ids.uniq.compact.join(' ,') : nil)
  end

  def adapter_name
    return (self.adapter.nil? ? runtype_adapter : adapter.runtype_adapter)
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
    if sample_conc_uom == 'ng/ul'
      return sample_conc
    elsif pcr_size.nil? || sample_conc.nil?
      return nil
    else
      return sample_conc * (pcr_size * BASE_GRAMS_PER_MOL) / 1000000
    end
  end
  
  def set_default_values
    self.lib_status = 'L'
    self.lib_conc_uom = 'pM'
    #self.sample_conc_uom = 'ng/ul'
  end

  def self.next_lib_barcode
    barcode_max = self.where("barcode_key LIKE ? AND barcode_key NOT LIKE ? AND LENGTH(barcode_key) = 7", 'L%', 'L6%').maximum(:barcode_key)
    return (barcode_max ? barcode_max.succ : 'L000001')
  end

  def self.max_id_barcode
    id_max = self.maximum(:id)
    return (id_max ? self.where('id = ?', id_max).first.barcode_key : 'None')
  end

  def self.find_for_query(condition_array, mplex_flag)
    libsample_join = (mplex_flag == 'M' ? 'INNER' : 'LEFT')
    self.select("seq_libs.*, COUNT(DISTINCT(flow_cells.id)) AS 'seq_run_cnt', COUNT(DISTINCT(flow_lanes.id)) AS 'seq_lane_cnt', " +
                    "COUNT(align_qc.id) AS 'qc_lane_cnt'")
        .joins("#{libsample_join} JOIN lib_samples on lib_samples.seq_lib_id = seq_libs.id
              LEFT JOIN processed_samples ON lib_samples.processed_sample_id = processed_samples.id
              LEFT JOIN flow_lanes ON flow_lanes.seq_lib_id = seq_libs.id
              LEFT JOIN align_qc ON align_qc.flow_lane_id = flow_lanes.id
              LEFT JOIN flow_cells ON flow_lanes.flow_cell_id = flow_cells.id").where(sql_where(condition_array)).group('seq_libs.id')
  end
  
  def self.find_for_export(id)
    self.find(id).includes(:flow_lanes => [:flow_cell, :align_qc]).where("flow_cells.flowcell_status <> 'F'")
  end

  def self.find_all_for_export(seqlib_ids)
    self.includes(:flow_lanes, :processed_samples).where("seq_libs.id IN (?)", seqlib_ids).all
  end
  
  def self.unique_projects
    # Exclude blank or NULL projects
    self.select(:project).order(:project).where("project > ''").uniq
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
  
  def self.load_from_xls(libs_sheet, lib_params, start_barcode)
    alignment_ref = AlignmentRef.find(lib_params[:alignment_ref_id]).alignment_key
    runtype_adapter = Adapter.find(lib_params[:adapter_id]).runtype_adapter
    oligo_pool = Pool.get_pool_label(lib_params[:pool_id])
    owner_id = Researcher.find_user_id(lib_params[:owner_name])
    barcode = start_barcode
    last_barcode = 'None'
    libs_loaded = 0; libs_errors = 0

    SeqLib.transaction do
      libs_sheet.each_with_index do |lib_row, i|
        next if i < 1  # Skip header row
        barcode = (lib_row[0].blank? ? (i == 1 ? start_barcode : barcode.succ) : lib_row[0])
        lib_name = lib_row[1]
        adapter_tag = lib_row[2]
        source_DNA   = lib_row[3]
        lib_size  = lib_row[4]
        sample_conc = lib_row[5]
        lib_conc  = lib_row[6]
        notebook_ref = lib_row[7]
        notes = lib_row[8]
        break if lib_name.blank?

        seq_lib = SeqLib.new(:barcode_key => barcode,
                           :lib_name => lib_name,
                           :library_type => 'S',
                           :protocol_id => lib_params[:protocol_id],
                           :owner => lib_params[:owner],
                           :preparation_date => lib_params[:preparation_date],
                           :adapter_id => lib_params[:adapter_id],
                           :runtype_adapter => runtype_adapter,
                           :alignment_ref_id => lib_params[:alignment_ref_id],
                           :alignment_ref => alignment_ref,
                           :sample_conc => sample_conc,
                           :sample_conc_uom => lib_params[:sample_conc_uom],
                           :lib_conc_requested => lib_conc,
                           :quantitation_method => lib_params[:quantitation_method],
                           :pcr_size => lib_size,
                           :pool_id => lib_params[:pool_id],
                           :oligo_pool => oligo_pool,
                           :notebook_ref => notebook_ref,
                           :notes => notes,
                           :updated_by => owner_id,
                           :created_at => Time.now)
        seq_lib.lib_samples.build(:sample_name => lib_name,
                           :source_DNA => source_DNA,
                           :processed_sample_id => ProcessedSample.find_psample_id(source_DNA),
                           :adapter_id => lib_params[:adapter_id],
                           :index1_tag_id => IndexTag.find_tag_id(lib_params[:adapter_id], 1, adapter_tag),
                           :notes => notes,
                           :updated_by => owner_id,
                           :created_at => Time.now)

        # Raise exception, rollback transaction, and exit if save fails due to validation error(s)
        if !seq_lib.valid?
          @invalid_lib = seq_lib
          raise ActiveRecord::Rollback
        end
        seq_lib.save!
        libs_loaded += 1
        last_barcode = barcode
      end  # End of lib row (Excel sheet) loop
    end  # End of transaction
    return libs_loaded, @invalid_lib ||= nil
  end

  def self.upd_mplex_splex(splex_lib)
    # Find all cases where supplied sequencing library is one of the 'samples' in a multiplex library
    lib_samples = LibSample.find_all_by_splex_lib_id(splex_lib.id)
    
    # If any cases found, collect all the multiplex libraries and their associated 'samples'(=singleplex libs)
    if !lib_samples.nil?
      mplex_ids  = lib_samples.collect(&:seq_lib_id)
      mplex_libs = self.find_all_by_id(mplex_ids, :include => {:lib_samples => :splex_lib})
      
      mplex_libs.each do |lib|
        self.upd_mplex_fields(lib) if lib.barcode_key[0,1] == 'L'
      end
    end
  end
  
  def self.upd_mplex_fields(mplex_lib)
    # Determine if all pools for associated samples are the same, if so, update multiplex pool accordingly
    # Determine if all adapters for associated samples are the same, if so, update adapter accordingly

    slib_pools = mplex_lib.lib_samples.collect{|lsamp| [lsamp.splex_lib.pool_id, (lsamp.splex_lib.oligo_pool ? lsamp.splex_lib.oligo_pool : '')]}
    slib_adapters = mplex_lib.lib_samples.collect{|lsamp| lsamp.splex_lib.adapter_id}
        
    if slib_pools.uniq.size > 1 
      self.update(mplex_lib.id, :oligo_pool => 'Multiple')
    else
      self.update(mplex_lib.id, :pool_id => slib_pools[0][0], :oligo_pool => slib_pools[0][1])
    end
        
    if slib_adapters.uniq.size > 1
      self.update(mplex_lib.id, :adapter_id => Adapter.unscoped.where('runtype_adapter = "Multiple"').first.id)
    else
      self.update(mplex_lib.id, :adapter_id => slib_adapters[0])
    end
  end
 
end
