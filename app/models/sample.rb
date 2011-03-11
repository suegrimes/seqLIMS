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
#  old_barcode              :string(20)
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
#  updated_by               :string(50)
#  created_at               :datetime
#  updated_at               :timestamp       not null
#

class Sample < ActiveRecord::Base
  belongs_to :patient
  belongs_to :sample_characteristic
  belongs_to :source_sample, :class_name => 'Sample', :foreign_key => 'source_sample_id'
  belongs_to :user, :foreign_key => 'updated_by'
  belongs_to :storage_location
  has_one    :histology
  has_many :processed_samples
  
  #before_validation :check_sample_date
  
  validates_presence_of :barcode_key
  validates_uniqueness_of :barcode_key, :message => 'is not unique'
  validates_presence_of :sample_date, :if => Proc.new { |a| a.new_record? }
  validates_date :sample_date, :allow_blank => true
  #validates_format_of :barcode_key, :with => /^([^\.])*$/, :message => "invalid - cannot use '.'"  # only use this validation if source_sample_id is null
  
  # Set date parameters for use in date_select lists.
  # Start year will be 2001, end year will be current year
  START_YEAR = 2000
  END_YEAR   = Time.now.strftime('%Y').to_i
  FLDS_FOR_COPY = (%w{sample_type sample_tissue left_right tissue_preservation sample_container vial_type amount_uom storage_location_id})
  SOURCE_FLDS_FOR_COPY = (%w{sample_characteristic_id patient_id tumor_normal sample_type sample_tissue left_right tissue_preservation})
 
  #def check_sample_date
    #sample date cannot be blank for new record, or for existing record if a sample date currently exists for that record
    #self.errors.add(:sample_date, "cannot be blank") if self.new_record? || !sample_date.blank?
  #end
  
  def before_save
    self.patient_id  = self.sample_characteristic.patient_id
    self.sample_date = self.sample_characteristic.collection_date if self.source_sample_id.nil?
  end
  
  def before_create
    self.amount_rem = self.amount_initial
  end
 
  def barcode_sort
    (source_barcode_key.blank? ? barcode_key : source_barcode_key )
  end
  
  def barcode_num
    barcode_key.slice(barcode_key.index('.'), barcode_key.length)
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
  
  def self.next_dissection_barcode(source_sample_id, source_barcode)
    barcode_max = self.maximum(:barcode_key, :conditions => ["source_sample_id = ? AND barcode_key LIKE ?", source_sample_id.to_i, source_barcode + '%'])
    if barcode_max
      return barcode_max.succ   # Increment last character of string (eg A->B)
    else
      return source_barcode + 'A' # No existing dissections, so add 'A' suffix
    end  
  end
  
  def self.find_newly_added_sample(sample_characteristic_id, barcode_key)
    self.find(:first, :include => [:sample_characteristic, :patient, :storage_location],
              :conditions => ["samples.sample_characteristic_id = ? AND samples.barcode_key = ?",
                               sample_characteristic_id, barcode_key])
  end
  
  def self.find_and_group_by_source(condition_array)
    samples = self.find_with_conditions(condition_array)
    return [samples.select{|sample| sample.source_sample_id == nil}.size, samples.size],
           samples.group_by {|sample| [sample.patient_id, sample.patient.mrn]}
  end
  
  def self.find_with_conditions(condition_array)
    self.find(:all, :include => [:patient, [:sample_characteristic => :pathology], :source_sample, :histology, :processed_samples],
                                 :conditions => condition_array,
                                 :order => 'samples.patient_id,
                                 (if(samples.source_barcode_key IS NOT NULL, samples.source_barcode_key, samples.barcode_key)), samples.barcode_key')                                
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
    self.find(:all, :include => [:patient, [:sample_characteristic => :pathology], :histology, :storage_location, :processed_samples],
              :conditions => ["samples.id IN (?)", sample_ids],
              :order => "samples.patient_id, samples.barcode_key")
  end
  
  def self.find_sample(sample_id)
    return self.find_by_id(sample_id)
  end
  
  def self.find_all_source_for_dissected
    samples = self.find(:all, :group => :source_sample_id, :conditions => "source_sample_id IS NOT NULL")
    return samples.collect(&:source_sample_id)
  end
  
  # Delete this method after changes once controller changed to use 'find_and_group_for_sample'
  def self.find_from_source_sample(source_sample_id)
    return self.find(:all, :include => [:sample_characteristic, :processed_samples],
                        :conditions => ['samples.id = ? OR samples.source_sample_id = ?', source_sample_id, source_sample_id])
                   #    :order => '(if(source_barcode_key IS NOT NULL, source_barcode_key, samples.barcode_key)), source_barcode_key)')
  end
 
end
