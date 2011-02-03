# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def toggle_div(div, div1=nil)
    update_page do |page|
      page[div].toggle
      page[div1].toggle if div1
    end
  end
  
  def remove_this_line(div)
    link_to_function "remove", "$(this).up('.#{div}').remove()"
  end
  
  def link_to_remove_fields(name, f)  
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")  
  end 
  
  def link_to_add_fields(name, f, association)  
    new_object = f.object.class.reflect_on_association(association).klass.new  
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|  
      render(association.to_s.singularize + "_fields", :f => builder)  
      end  
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))  
  end  
 
  def format_date(datetime)
    (datetime.nil? ? '' : datetime.strftime("%Y-%m-%d"))
  end
  
  def format_datetime(datetime)
    (datetime.nil? ? '' : datetime.strftime("%Y-%m-%d %I:%M%p"))
  end
  
  def format_conc(conc)
    (conc.nil? ? '' : sprintf('%02.2f', conc))
  end
  
  def pct_with_parens(pct)
    sprintf('(%02d%s)', pct, '%')
  end
  
  def user_role_is?(role)
    (current_user && current_user.has_role?(role, 'admin_defaults_to_true'))
  end

end
  