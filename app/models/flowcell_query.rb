# == Schema Information
#
# Table name: flowcell_queries
#
#  run_nr       :string
#  machine_name :string
#  from_date    :date
#  to_date      :date
#

class FlowcellQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  column :run_nr,    :string
  column :machine_type, :string
  column :from_date, :date
  column :to_date,   :date

  validates_format_of :run_nr, :with => /^\d+$/, :allow_blank => true, :message => "must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
end
