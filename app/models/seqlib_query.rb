# == Schema Information
#
# Table name: seqlib_queries
#
#  owner         :string
#  project       :string
#  lib_name      :string
#  barcode_from  :string
#  barcode_to    :string
#  alignment_ref :string
#  from_date     :date
#  to_date       :date
#

class SeqlibQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end

  column :patient_id,    :integer
  column :owner,         :string
  column :project,       :string
  column :lib_name,      :string
  column :barcode_string, :string
  column :alignment_ref, :string
  column :from_date,     :date
  column :to_date,       :date

  validates_date :to_date, :from_date, :allow_blank => true

  SEARCH_FLDS = %w{lib_name}
  SEQLIB_FLDS = %w{owner project alignment_ref}
  PSAMPLE_FLDS = %w{patient_id}
  ALL_FLDS    = SEQLIB_FLDS | SEARCH_FLDS | PSAMPLE_FLDS

end
