# == Schema Information
#
# Table name: samples
#
#  id                       :integer(4)      not null, primary key
#  patient_id               :integer(4)
#  sample_characteristic_id :integer(4)
#  source_sample_id         :integer(4)
#  source_barcode_key       :string(20)
#  barcode_key              :string(20)      default(""), not null
#  alt_identifier           :string(20)
#  sample_date              :date
#  sample_type              :string(50)
#  sample_tissue            :string(50)
#  left_right               :string(1)
#  tissue_preservation      :string(25)
#  tumor_normal             :string(25)
#  sample_container         :string(20)
#  vial_type                :string(30)
#  amount_initial           :decimal(10, 3)  default(0.0)
#  amount_rem               :decimal(10, 3)  default(0.0)
#  amount_uom               :string(20)
#  sample_remaining         :string(2)
#  storage_location_id      :integer(4)
#  storage_shelf            :string(10)
#  storage_boxbin           :string(25)
#  comments                 :string(255)
#  updated_by               :integer(2)
#  created_at               :datetime
#  updated_at               :timestamp       not null
#

class Sample < ActiveRecord::Base
  include LimsCommon
  
  #attr_accessible :barcode_key, :source_sample_id, :amount_uom, :sample_date, :tumor_normal, :sample_container, :vial_type, :amount_initial, :sample_remaining, :comments, :amount_rem
  
  belongs_to :patient
  belongs_to :sample_characteristic
  belongs_to :source_sample, :class_name => 'Sample', :foreign_key => 'source_sample_id'
  has_many   :samples, :foreign_key => 'source_sample_id'
  belongs_to :user, :foreign_key => 'updated_by'
  has_one    :histology, :dependent => :destroy
  has_many :processed_samples
  has_one :sample_storage_container, :as => :stored_sample, :dependent => :destroy
  has_many :attached_files, :as => :sampleproc
  
  accepts_nested_attributes_for :sample_storage_container
  
  validates_presence_of :barcode_key
  validates_uniqueness_of :barcode_key, :message => 'is not unique'

  #validates_presence_of :sample_date, :if => Proc.new {|a| a.new_record? }
  validates_date :sample_date, :allow_blank => true
  
  #validates_format_of :barcode_key, :with => /^([^\.])*$/, :message => "invalid - cannot use '.'"  # only use this validation if source_sample_id is null
  
  #before_validation :check_sample_date

  # Set date parameters for use in date_select lists.
  # Start year will be 2001, end year will be current year
  START_YEAR = 2000
  END_YEAR   = Time.now.strftime('%Y').to_i
  FLDS_FOR_COPY = (%w{sample_type sample_tissue left_right tissue_preservation sample_container vial_type amount_uom})
  SOURCE_FLDS_FOR_DISSECT = (%w{sample_characteristic_id patient_id tumor_normal sample_type sample_tissue left_right tissue_preservation})
 
  #def check_sample_date
    #sample date cannot be blank for new record, or for existing record if a sample date currently exists for that record
    #self.errors.add(:sample_date, "cannot be blank") if self.new_record? || !sample_date.blank?
  #end
  
  before_create :upd_from_source_sample
  before_save :upd_parent_ids
  after_update :upd_dissections

  def upd_from_source_sample
    self.amount_rem = self.amount_initial
    # If new dissected sample, update appropriate fields with source sample info
    if !self.source_sample_id.nil?
      self.tumor_normal = self.source_sample.tumor_normal
      self.sample_type  = self.source_sample.sample_type
      self.sample_tissue = self.source_sample.sample_tissue
      self.left_right = self.source_sample.left_right
      self.tissue_preservation = self.source_sample.tissue_preservation
    end
  end

  def upd_parent_ids
    if self.source_sample_id.nil?
      self.sample_date = self.sample_characteristic.collection_date
      self.patient_id = self.sample_characteristic.patient_id
      self.sample_characteristic_id = self.sample_characteristic.id
    else
      self.patient_id = self.source_sample.patient_id
      self.sample_characteristic_id = self.source_sample.sample_characteristic_id
    end
  end

  # After save, look for any dissections from the source sample updated, and update those as well
  def upd_dissections
    source_sample_id = self.id 
    dissected_samples = Sample.find_all_by_source_sample_id(source_sample_id)
    if !dissected_samples.nil?
      source_flds_for_upd = SOURCE_FLDS_FOR_DISSECT.delete_if {|sfld| sfld == 'tumor_normal' && !self.tumor_normal.nil?}
      sample_params = build_params_from_obj(self, source_flds_for_upd)
      dissected_samples.each do |dsample|
        dsample.update_attributes(sample_params)
      end
    end
  end
  
  def barcode_sort
    (source_barcode_key.blank? ? barcode_key : source_barcode_key )
  end
  
  def barcode_num
    barcode_key.slice(barcode_key.index('.'), barcode_key.length)
  end
  
  def barcode_incl_nccc
    (alt_identifier.nil? ? barcode_key : [barcode_key, " (", alt_identifier, ")"])
  end
  
  def clinical_sample
    (source_sample_id.blank? ? 'yes' : 'no')
  end
  
  def sample_category
    type_of_sample = (clinical_sample == 'yes'? sample_type : 'Dissection')
    return [type_of_sample, sample_tissue].join('/')
  end
  
  def container_type
    [sample_container, vial_type].join('/')
  end
  
  def sample_amt
    # Pull out value in parentheses (eg. from Volume (ul), pull out ul)
    if (amount_uom =~ /\(/ && amount_uom =~ /\(/)
      uom = amount_uom.match(/\((.*)\)/)[1]
    else
      uom = amount_uom
    end
    return [amount_initial.to_s, uom].join(' ')
  end
  
  def room_and_freezer
    (sample_storage_container ? sample_storage_container.room_and_freezer : '')
  end
  
  def container_and_position
    (sample_storage_container ? sample_storage_container.container_and_position : '')
  end
  
  def self.next_dissection_barcode(source_sample_id, source_barcode)
    barcode_max = self.where("source_sample_id = ? AND barcode_key LIKE ?", source_sample_id.to_i, source_barcode + '%').maximum(:barcode_key)
    #barcode_max = self.maximum(:barcode_key, :conditions => ["source_sample_id = ? AND barcode_key LIKE ?", source_sample_id.to_i, source_barcode + '%'])
    if barcode_max
      return barcode_max.succ   # Increment last character of string (eg A->B)
    else
      return source_barcode + 'A' # No existing dissections, so add 'A' suffix
    end  
  end
  
  def self.find_newly_added_sample(sample_characteristic_id, barcode_key)
    condition_array = ["samples.sample_characteristic_id = ? AND samples.barcode_key = ?", sample_characteristic_id, barcode_key]
    self.includes(:sample_characteristic, :patient, :sample_storage_container).where(*condition_array).first
    #self.find(:first, :include => [:sample_characteristic, :patient, :sample_storage_container],
    #          :conditions => ["samples.sample_characteristic_id = ? AND samples.barcode_key = ?",
    #                           sample_characteristic_id, barcode_key])
  end
  
  def self.getwith_attach(id)
    self.find(id, :include => :attached_files)
  end
  
  def self.find_and_group_by_source(condition_array)
    samples = self.find_with_conditions(condition_array)
    return [samples.where("source_sample_id IS NULL").count, samples.count],
            samples.group_by {|sample| [sample.patient_id, sample.patient.mrn]}
  end
  
  def self.find_with_conditions(condition_array)
    #self.find(:all, :include => [:patient, [:sample_characteristic => :pathology], :source_sample, :histology, :sample_storage_container, :processed_samples],
    #                             :conditions => condition_array,
    #                             :order => 'samples.patient_id,
    #                             (if(samples.source_barcode_key IS NOT NULL, samples.source_barcode_key, samples.barcode_key)), samples.barcode_key')
    self.includes(:patient, {:sample_characteristic => :pathology}, :source_sample, :histology, :sample_storage_container, :processed_samples)
        .where(*condition_array).order('samples.patient_id')
  end
  
  def self.find_and_group_for_patient(patient_id, id_type=nil)
    self.find_and_group_by_source(['samples.patient_id = ?', patient_id])
  end
  
  def self.find_and_group_for_clinical(sample_characteristic_id)
    self.find_and_group_by_source(['samples.sample_characteristic_id = ?', sample_characteristic_id])
  end
  
  def self.find_and_group_for_sample(source_sample_id)
    self.find_and_group_by_source(['samples.id = ? OR samples.source_sample_id = ?', source_sample_id, source_sample_id])
  end
  
  def self.find_for_export(sample_ids)
    self.includes(:patient, [:sample_characteristic => :pathology], :histology, :sample_storage_container, :processed_samples)
        .where("samples.id IN (?)", sample_ids).order("samples.patient_id, samples.barcode_key").all
    #self.find(:all, :include => [:patient, [:sample_characteristic => :pathology], :histology, :sample_storage_container, :processed_samples],
    #          :conditions => ["samples.id IN (?)", sample_ids],
    #          :order => "samples.patient_id, samples.barcode_key")
  end
  
  def self.find_sample(sample_id)
    return self.find_by_id(sample_id)
  end
  
  def self.find_all_source_for_dissected
    #samples = self.find(:all, :group => :source_sample_id, :conditions => "source_sample_id IS NOT NULL")
    samples = self.where("source_sample_id IS NOT NULL").group(:source_sample_id)
    return samples.collect(&:source_sample_id)
  end
  
  # Delete this method after changes once controller changed to use 'find_and_group_for_sample'
  def self.find_from_source_sample(source_sample_id)
    return self.find(:all, :include => [:sample_characteristic, :processed_samples],
                        :conditions => ['samples.id = ? OR samples.source_sample_id = ?', source_sample_id, source_sample_id])
                   #    :order => '(if(source_barcode_key IS NOT NULL, source_barcode_key, samples.barcode_key)), source_barcode_key)')
  end
  
  def self.count_samples_in_range(rstart, rend)
    return self.count(:conditions => ["source_sample_id IS NULL AND CAST(barcode_key AS UNSIGNED) BETWEEN ? AND ?", rstart, rend])
  end
 
end
