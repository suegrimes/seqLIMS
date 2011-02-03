# == Schema Information
#
# Table name: machine_incidents
#
#  id                   :integer(4)      not null, primary key
#  seq_machine_id       :integer(4)
#  incident_date        :date            not null
#  incident_description :string(255)     default(""), not null
#  updated_by           :integer(4)
#  created_at           :datetime
#  updated_at           :timestamp
#

class MachineIncident < ActiveRecord::Base
  belongs_to :seq_machine
  
  validates_date :incident_date
end
