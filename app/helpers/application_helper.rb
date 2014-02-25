module ApplicationHelper
  
  def break_clear(content=nil)
    out = '<br />'
    out << '<table class="break_clear" width="100%"><tr><td>'
    out << content if !content.nil?
    out << '</td></tr></table>'
    out
  end
  
  def row_underline(cols)
    content_tag(:tr, content_tag(:td, nil, {:style => "border-bottom: 1px solid #999; padding-top:.25em; margin-bottom:.75em;", :colspan => cols}))
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
  
  def format_conc(conc, val_if_nil='--')
    (conc.nil? ? val_if_nil : sprintf('%02.2f', conc))
  end

  def delimited_number(num)
    (num.nil? ? '' : number_with_delimiter(num, :delimiter => ','))
  end

  def pct_with_parens(pct)
    (pct.nil? ? '' : sprintf('(%02d%s)', pct, '%'))
  end
  
  def user_role_is?(role)
    (current_user && current_user.has_role?(role, 'admin_defaults_to_true'))
  end
  
  def user_has_access?(user_roles, valid_roles)
    # if user has admin role, or intersection of user_roles and valid_roles is not empty, user has access
    (user_roles.include?("admin") || (user_roles & valid_roles).size > 0 ? true : false)
  end
  
  def name_of_klass(obj)
    case obj.class.name
      when 'FlowCell' then 'Seq Run'
      when 'ProcessedSample' then 'Extracted Sample'
      else obj.class.name.split(/(?=[A-Z])/).join(' ')
    end
  end
  
end
