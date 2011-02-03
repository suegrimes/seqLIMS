module SampleCharacteristicsHelper
  
  def add_sample_link(name)
    #button_to_function name do |page|
    #link_to_function(image_tag("here.png")) do |page|
    link_to_function name do |page|
      page.insert_html :bottom, :samples, :partial => 'samples_form',
                                          :locals => {:sample => Sample.new,
                                                      :removable => 'yes'}
    end
  end 
end
