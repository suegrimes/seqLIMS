# == Schema Information
#
# Table name: sample_characteristics
#
#  id                  :integer(4)      not null, primary key
#  patient_id          :integer(4)
#  collection_date     :date
#  clinic_or_location  :string(100)
#  consent_protocol_id :integer(4)
#  consent_nr          :string(15)
#  gender              :string(1)
#  ethnicity           :string(35)
#  race                :string(70)
#  nccc_tumor_id       :string(20)
#  nccc_pathno         :string(20)
#  pathology_id        :integer(4)
#  pathology           :string(50)
#  comments            :string(255)
#  updated_by          :integer(2)
#  created_at          :datetime
#  updated_at          :datetime
#

class SampleCharacteristic < ActiveRecord::Base
  require 'ezcrypto'
  
  has_many :samples, :dependent => :destroy
  belongs_to :patient
  belongs_to :consent_protocol
  belongs_to :pathology
  
  accepts_nested_attributes_for :samples
  
  validates_presence_of :collection_date, :if => Proc.new { |a| a.new_record? }
  validates_date :collection_date, :allow_blank => true
  validates_presence_of :consent_protocol_id, :clinic_or_location
  
  #after_save :save_sample
  
  def before_create
    self.gender    = self.patient.gender
    self.ethnicity = self.patient.ethnicity
    self.race      = self.patient.race
  end
  
  def before_save
    self.consent_nr = self.consent_protocol.consent_nr if self.consent_protocol
  end
  
  def consent_descr
    (consent_protocol.nil? ? consent_nr : [consent_nr, consent_protocol.consent_abbrev].join('/'))
  end
  
  def from_nccc?
    (clinic_or_location == 'NCCC' ? true : false)
  end
  
  def self.find_with_samples(patient_id=nil)
    condition_array = (patient_id.nil? ? nil : ['sample_characteristics.patient_id = ?', patient_id])
    self.includes(:samples).where(*condition_array).order('sample_characteristics.patient_id, samples.barcode_key')
    #self.find(:all, :include => :samples,
    #                :order   => 'sample_characteristics.patient_id, samples.barcode_key',
    #                :conditions => condition_array)
  end

  def self.find_and_group_with_conditions(condition_array=[])
    #sample_characteristics = self.find(:all, :include => [:patient, :samples],
    #                :order   => 'sample_characteristics.patient_id, sample_characteristics.collection_date DESC',
    #               :conditions => condition_array)
    sample_characteristics = self.includes(:patient, :samples).where(sql_where(condition_array))
                                 .order('sample_characteristics.patient_id, sample_characteristics.collection_date DESC')
    return sample_characteristics.size, 
           sample_characteristics.group_by {|samp_char| [samp_char.patient_id, samp_char.patient.mrn]}
  end

end
