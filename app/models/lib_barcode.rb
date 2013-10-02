# == Schema Information
#
# Table name: lib_barcodes
#
#  id            :integer(4)      not null, primary key
#  barcode_min   :integer(3)      not null
#  barcode_max   :integer(3)      not null
#  assigned_to   :integer(2)      not null
#  assigned_date :date            not null
#  created_at    :date
#  updated_at    :timestamp
#

class LibBarcode < ActiveRecord::Base
  BARCODE_MIN = self.order("barcode_min ASC").first
  BARCODE_MAX = self.order("barcode_max DESC").first
end
