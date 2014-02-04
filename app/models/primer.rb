# == Schema Information
#
# Table name: primers
#
#  id              :integer          not null, primary key
#  gene_family     :string(10)
#  gene_code       :string(30)
#  primer_name     :string(50)       not null
#  primer_sequence :string(80)       not null
#  created_at      :datetime         not null
#  updated_at      :timestamp
#

class Primer < InventoryDB
  has_and_belongs_to_many :pools
  validates_presence_of :primer_name
  validates_uniqueness_of :primer_name
end
