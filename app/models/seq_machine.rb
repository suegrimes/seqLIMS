# == Schema Information
#
# Table name: seq_machines
#
#  id            :integer(4)      not null, primary key
#  machine_name  :string(20)      default(""), not null
#  bldg_location :string(12)
#  machine_type  :string(20)
#  machine_desc  :string(50)
#  last_seq_num  :integer(2)
#  notes         :string(255)
#  created_at    :datetime
#  updated_at    :timestamp
#

class SeqMachine < ActiveRecord::Base
  has_many :machine_incidents, :dependent => :destroy
  accepts_nested_attributes_for :machine_incidents, :reject_if => lambda { |a| a[:incident_description].blank? }, :allow_destroy => true
  
  scope :sequencers, :conditions => ['machine_name <> ?', 'Run_Number' ]
  
  #MACHINE_TYPES = %w{GAIIx HiSeq MiSeq}
  MACHINE_TYPES = self.sequencers.find(:all, :select => "DISTINCT(machine_type)", :order => :machine_type).map(&:machine_type) 
  
  def machine_name_and_type
    return [machine_name, '(', machine_type, ')']
  end
  
  def self.populate_dropdown
    return self.sequencers.find(:all, :order => 'bldg_location, machine_name')
  end
  
  def self.populate_dropdown_grouped
    sequencers_by_bldg = self.sequencers.find(:all, :select => 'id, bldg_location, machine_name',
                                                    :order  => 'bldg_location, machine_name').group_by(&:bldg_location)
    return sequencers_by_bldg.collect {|bldg, attrs| [bldg, attrs.collect{|attr| [attr.machine_name, attr.id]}]}
  end
  
  def self.find_and_incr_run_nr
    seq_run_nr = self.find_by_machine_name('Run_Number')
    seq_run_nr.update_attributes(:last_seq_num => seq_run_nr.last_seq_num + 1) 
    return seq_run_nr.last_seq_num
  end
  
  def self.find_all_with_incidents
    self.sequencers.find(:all, :include => :machine_incidents,
                               :order => "seq_machines.bldg_location, seq_machines.machine_name, machine_incidents.incident_date DESC")
  end
  
  def self.find_with_incidents(id)
    self.find(id, :include => :machine_incidents, :order => 'machine_incidents.incident_date DESC')
  end
  
end
