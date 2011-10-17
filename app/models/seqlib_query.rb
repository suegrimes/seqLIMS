# == Schema Information
#
# Table name: seqlib_queries
#
#  owner         :string
#  project       :string
#  lib_name      :string
#  barcode_key   :string
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
  
  column :owner,         :string
  column :project,       :string
  column :lib_name,      :string
  column :barcode_key,   :string
  column :alignment_ref, :string
  column :from_date,     :date
  column :to_date,       :date

  validates_date :to_date, :from_date, :allow_blank => true
  
  SEQLIB_FLDS = %w{owner project barcode_key lib_name alignment_ref}
  ALL_FLDS    = SEQLIB_FLDS
end
