# plugin init file for rails
# this file will be picked up by rails automatically and
# add the upload_column extensions to rails

require "#{Rails.root}/lib/upload_column"
require "#{Rails.root}/lib/upload_column/rails/upload_column_helper"
require "#{Rails.root}/lib/upload_column/rails/action_controller_extension"
require "#{Rails.root}/lib/upload_column/rails/asset_tag_extension"

#Mime::Type.register "image/png", :png
#Mime::Type.register "image/jpeg", :jpg
#Mime::Type.register "image/gif", :gif

UploadColumn::Root = Rails.root