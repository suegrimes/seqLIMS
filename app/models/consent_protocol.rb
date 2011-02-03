# == Schema Information
#
# Table name: consent_protocols
#
#  id               :integer(4)      not null, primary key
#  consent_nr       :string(8)
#  consent_name     :string(100)
#  consent_abbrev   :string(50)
#  email_confirm_to :string(255)
#  created_at       :datetime
#  updated_at       :timestamp       not null
#

class ConsentProtocol < ActiveRecord::Base
  
  def name_ver
    [consent_nr, consent_abbrev].join('/') 
  end
  
  def self.find_and_sort_all
    self.populate_dropdown
  end
  
  def self.populate_dropdown
    self.find(:all, :order => 'CAST(consent_nr AS UNSIGNED)')
  end
end
