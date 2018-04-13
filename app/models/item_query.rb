# == Schema Information
#
# Table name: no_tables
#
#  company_name   :string
#  requester_name :string
#  item_status    :string
#  deliver_site   :string
#  from_date      :date
#  to_date        :date
#

class ItemQuery < NoTable
  column :company_name, :string
  column :requester_name,  :string
  column :ordered_status,  :string
  column :received_status,  :string
  column :deliver_site, :string
  column :from_date,    :date
  column :to_date,      :date

  validates_date :to_date, :from_date, :allow_blank => true
  
  ITEM_FLDS = %w{company_name requester_name deliver_site}
  ORDER_FLDS = %w{deliver_site}
end
