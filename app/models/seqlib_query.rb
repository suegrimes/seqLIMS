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
  
  column :owner,         :string
  column :project,       :string
  column :lib_name,      :string
  column :barcode_from,  :string
  column :barcode_to,    :string
  column :alignment_ref, :string
  column :from_date,     :date
  column :to_date,       :date

  validates_date :to_date, :from_date, :allow_blank => true
  
  SEQLIB_FLDS = %w{owner project lib_name alignment_ref}
  ALL_FLDS    = SEQLIB_FLDS
  
  def validate
    if !barcode_to.blank?
      errors.add(:barcode_from, "- must be entered if ending barcode entered") if barcode_from.blank?
      errors.add(:barcode_to, "- cannot be less than beginning barcode") if barcode_to.to_i < barcode_from.to_i
    end
  end
end
