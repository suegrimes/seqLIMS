# == Schema Information
#
# Table name: molassay_queries
#
#  patient_id :string
#  from_date  :date
#  to_date    :date
#  owner      :string
#

class MolassayQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  column :patient_id,  :string
  column :from_date,   :date
  column :to_date,     :date
  column :owner,       :string

  validates_format_of :patient_id, :with => /^\d+$/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  
  ASSAY_FLDS   = %w{owner}
  PSAMPLE_FLDS = %w{patient_id}
  ALL_FLDS     = ASSAY_FLDS
end
