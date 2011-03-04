module SampleQueriesHelper
  def have_comments?(sample)
    if (sample.sample_characteristic.pathology && !sample.sample_characteristic.pathology.comments.blank?) 
      return true
    elsif !sample.comments.blank?
      return true
    else
      return false
    end
  end
end
