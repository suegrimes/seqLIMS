# == Schema Information
#
# Table name: patients
#
#  id                    :integer          not null, primary key
#  clinical_id_encrypted :binary(30)
#  organism              :string(25)
#  gender                :string(1)
#  ethnicity             :string(35)
#  race                  :string(70)
#  hipaa_encrypted       :binary(255)
#  created_at            :datetime
#  updated_at            :datetime
#


class Patient < ActiveRecord::Base
  require 'ezcrypto'
  
  has_many :sample_characteristics
  has_many :samples
  
  after_save :upd_sample_characteristics
  after_create :upd_na_mrn
  
  def self.get_patient_id(mrn, not_found_action='none')
    patient_id  = self.find_id_using_mrn(mrn) unless mrn == 'NA' && not_found_action == 'add'
 
    # Return true if new patient added, otherwise false
    if !patient_id && not_found_action == 'add'
      patient_record = self.new(:mrn => mrn)
      patient_record.save
      return patient_record.id, true
    else
      return patient_id, false
    end
    
  end
  
#  def self.upd_demographics(id, gender, race, ethnicity)
#    attr_hash = {}
#    patient = self.find(id)
#    attr_hash[:gender]    = gender    if gender != 'U'
#    attr_hash[:race]      = race      if race   != '[Unknown]'
#    attr_hash[:ethnicity] = ethnicity if ethnicity != '[Unknown]'
#    patient.update_attributes(attr_hash)
#  end
#  
  def self.loadrecs(file_path)
    rec_cnt = 0
    
    CSV.foreach(file_path, {:headers => :first_row, :col_sep => "\t"}) do |row|
      @patient = self.find_by_id(row[2].to_i)
      if row[1] == 'na'
        @patient.update_attributes(:mrn => row[0]) if row[1] == 'na'
        rec_cnt += 1
      end
    end
    
    return rec_cnt
    
  end

## NEED TO make this protected or private?  If so, cannot call any of these methods from 
## sample_characteristics controller?
  def self.find_id_using_mrn(mrn)
    mrn_ids = self.all.map {|p| [p.mrn, p.id]}
    
    patient_nums = mrn_ids.assoc(mrn) if !mrn_ids.empty?
    patient_id   = patient_nums[1]    if patient_nums
    return patient_id
  end
  
  def self.find_id_from_mrn(mrn)
    return self.find_by_clinical_id_encrypted(key.encrypt(mrn)).id
  end

  def mrn
    key.decrypt(clinical_id_encrypted)
  end
  
  def hipaa_data
    key.decrypt(hipaa_encrypted)
  end
 
  def mrn=(mrn)
    self.clinical_id_encrypted = key.encrypt(mrn)
  end
  
  def hipaa_data=(hipaa_data)
    self.hipaa_encrypted = key.encrypt(hipaa_data)
  end

private
  def key
    EzCrypto::Key.with_password(EZ_PSWD, EZ_SALT)
  end
  
  def upd_na_mrn
    self.update_attributes(:mrn => ['NA_', id.to_s].join) if mrn == 'NA'
  end
  
  def upd_sample_characteristics
    sample_characteristics.each do |schar|
      schar.update_attributes(:gender => gender,
                              :race => race,
                              :ethnicity => ethnicity)
    end
  end
  
protected
  def validate
    errors.add(:clinical_id_encrypted, "mrn must be non-blank") if mrn.blank?
  end
end
