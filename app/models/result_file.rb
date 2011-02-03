# == Schema Information
#
# Table name: result_files
#
#  id                 :integer(4)      not null, primary key
#  analysis_id        :integer(4)
#  rfile              :string(255)
#  rfile_content_type :string(100)
#  rfile_size         :integer(3)
#  notes              :string(255)
#  created_at         :datetime
#  updated_at         :timestamp       not null
#

class ResultFile < ActiveRecord::Base
  belongs_to :analysis
  upload_column :rfile, :extensions => %w(txt csv html htm xls xlsx doc docx ppt pptx jpg gif bmp)
  validates_integrity_of :rfile, :message => "invalid file extension"
end
