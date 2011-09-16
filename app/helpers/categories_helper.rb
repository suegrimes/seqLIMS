module CategoriesHelper
  def add_value_link(name, form) 
    link_to_function name do |page|
      page["add_val"].hide
      page.insert_html :bottom, :category, :partial => 'cat_value', 
                                           :locals => {:category_value => @category.category_values.build(:c_value => ''),
                                           :cform => form}    
    end
  end
  
  def remove_link_unless_new_record(fields)
    unless fields.object.new_record?
      out = ''
      out << fields.hidden_field(:_destroy)
      out << link_to_function("remove", "$(this).up('.#{fields.object.class.name.underscore}').hide(); $(this).previous().value = '1'")
      out
    end
  end
  
end
