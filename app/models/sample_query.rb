# == Schema Information
#
# Table name: sample_queries
#
#  mrn                 :string
#  patient_id          :string
#  barcode_from        :string
#  barcode_to          :string
#  gender              :string
#  consent_protocol_id :integer
#  clinic_or_location  :string
#  race                :string
#  ethnicity           :string
#  sample_tissue       :string
#  sample_type         :string
#  tissue_preservation :string
#  tumor_normal        :string
#  date_filter         :string
#  from_date           :date
#  to_date             :date
#  updated_by          :integer
#

class SampleQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  column :mrn,         :string
  column :patient_id,  :string
  column :barcode_from, :string
  column :barcode_to, :string
  column :alt_identifier, :string
  column :gender,      :string
  column :consent_protocol_id, :integer
  column :clinic_or_location, :string
  column :race, :string
  column :ethnicity, :string
  column :sample_tissue, :string
  column :sample_type, :string
  column :tissue_preservation, :string
  column :tumor_normal, :string
  column :date_filter, :string
  column :from_date,   :date
  column :to_date,     :date
  column :updated_by,  :integer

  validates_format_of :patient_id, :with => /^\d+$/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  
  SCHAR_FLDS = %w{patient_id gender race ethnicity consent_protocol_id clinic_or_location}
  SAMPLE_FLDS = %w{barcode_key alt_identifier tumor_normal sample_tissue sample_type tissue_preservation updated_by}
  ALL_FLDS    = SCHAR_FLDS | SAMPLE_FLDS
  
  def validate
    if !barcode_to.blank?
      errors.add(:barcode_from, "- must be entered if ending barcode entered") if barcode_from.blank?
      errors.add(:barcode_to, "- cannot be less than beginning barcode") if barcode_to < barcode_from
    end
  end
end
