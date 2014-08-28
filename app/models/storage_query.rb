# == Schema Information
#
# Table name: storage_queries
#

class StorageQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  column :mrn,            :string
  column :patient_id,     :string
  column :barcode_key, :string
  column :alt_identifier, :string
  column :consent_protocol_id, :integer
  column :clinic_or_location, :string
  column :sample_tissue, :string
  column :sample_type, :string
  column :tissue_preservation, :string
  column :tumor_normal, :string
  column :date_filter, :string
  column :from_date,   :date
  column :to_date,     :date

  validates_format_of :patient_id, :with => /^\d+$/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  
  SCHAR_FLDS = %w{consent_protocol_id clinic_or_location}
  SAMPLE_FLDS = %w{patient_id barcode_key alt_identifier tumor_normal sample_tissue sample_type tissue_preservation}
  ALL_FLDS    = SCHAR_FLDS | SAMPLE_FLDS

end
