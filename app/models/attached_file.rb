# == Schema Information
#
# Table name: attached_files
#
#  id                    :integer(4)      not null, primary key
#  sampleproc_id         :integer(4)      not null
#  sampleproc_type       :string(50)      default(""), not null
#  document              :string(255)
#  document_content_type :string(40)
#  document_file_size    :string(25)
#  notes                 :string(255)
#  updated_by            :integer(4)
#  created_at            :datetime
#

class AttachedFile < ActiveRecord::Base  
  FILES_ROOT = (SITE_URL.include?('stanford.edu') ? File.join(Rails.root, "..", "..", "shared", "attached_files") :
                                                    File.join(Rails.root, "..", "LIMSFiles", "AttachedFile"))
  
  belongs_to :sampleproc, :polymorphic => true
  
  upload_column :document, :store_dir => proc{|inst,attr| File.join(FILES_ROOT, inst.sampleproc_type)},
                           :filename  => proc{|record, file| "#{record.sampleproc_id}_#{file.basename}.#{file.extension}"},
                           :extensions => %w(txt csv doc docx xls xlsx jpg png gif tif ppt pptx) # List of valid extensions
  #validates_integrity_of :document, :message => "invalid file type - executables cannot be uploaded"
  validates_presence_of :document 
  
  def basename_with_ext
    # Return file basename, with extension (and with id prefix)
    #return document.to_s.split('/')[-1]
    return [sampleproc_id.to_s, '_', document.basename, '.', document.extension].join
  end
  
  def doc_fullpath
    return File.join(FILES_ROOT, sampleproc_type, basename_with_ext)
  end
end
