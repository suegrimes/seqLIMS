module SampleStorageContainersHelper
  def edit_path_by_type(sscontainer)
    if sscontainer.stored_sample && sscontainer.stored_sample.class.name == 'Sample'
      edit_sample_loc_path(sscontainer.stored_sample)
    elsif sscontainer.stored_sample && sscontainer.stored_sample.class.name == 'ProcessedSample'
      edit_processed_sample_path(sscontainer.stored_sample)
    elsif sscontainer.stored_sample && sscontainer.stored_sample.class_name == 'SeqLib'
      edit_seq_lib_path(sscontainer.stored_sample)
    else
      edit_sample_storage_container_path(sscontainer)
    end
  end
end