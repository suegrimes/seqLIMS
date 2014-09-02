class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticatedSystem
  include RoleRequirementSystem
  include LimsCommon
  before_filter :login_required
 
  #Make current_user accessible from model (via User.current_user)
  before_filter :set_current_user
  before_filter :log_user_action

  cache_sweeper :user_stamper

  rescue_from CanCan::AccessDenied do |exception|
    user_login = (current_user.nil? ? nil : current_user.login)
    flash[:error] = "Sorry #{user_login}, you are not authorized to access that page"
    redirect_to root_url
  end
  # 
  require 'csv'
  #require 'calendar_date_select'

  helper :all # include all helpers, all the time
  #
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'a7fa20ae329c39ca9cb722a7173c224f'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  #filter_parameter_logging :password, :mrn
  DateRange = Struct.new(:from_date, :to_date)

  def category_filter(categories, cat_name, output='collection')
    category_selected = categories.select{|cm| cm.category == cat_name}
    if output == 'string'
      return category_selected[0].category_values.map {|cv| cv.c_value}
    else
      return category_selected[0].category_values
    end  
  end
  
#  def base_barcode(barcode_key)
#    barcode_split = barcode_key.split('.')
#    return barcode_split[0]
#  end
  
  def barcode_type(barcode_key)
    barcode_split = barcode_key.split('.')
    if barcode_split.length == 1
      return 'S'
    else
      return barcode_split[-1][0,1] # first character of last substring after splitting by '.'
    end
  end
  
  def param_blank?(val)
    if val.nil?
      val_blank = true
    elsif val.is_a? Array
      #val_blank = (val.size == 1 && val[0].blank? ? true : false )
      # Hack due to change in Rails 3 which passes hidden value for collection_select/multiple and causes duplicate blank entry in array
      val_blank = (val.size == 1 && val[0].blank? ) || (val.size == 2 && val[0].blank? && val[1].blank?)
    else
       val_blank = val.blank?
    end
    return val_blank 
  end
  
  def array_to_string(arry, delim=',')
    if arry.nil? || arry.empty? 
      string_val = nil
    else
      string_val = arry.join(delim)
    end
    return string_val
  end
  
  def find_patient_nr(model, id)
    patient_id = model.constantize.find(id).patient_id
    return format_patient_nr(patient_id, 'array')
  end
  
  # If current_user can read MRN, format patient nr as id/mrn, otherwise just id
  def format_patient_nr(id, format='string')
    if can? :read, Patient
      patient = Patient.find(id)
    end  
    
    if patient
      patient_numbers = [id.to_s, patient.mrn]
      return (format == 'string' ? patient_numbers.join(' / ') : patient_numbers)
    else
      return (format == 'string' ? id.to_s : [id.to_s])
    end 
  end
  
  def find_barcode(model, id)
    model.constantize.find(id).barcode_key
  end
  
  def compound_string_params(str_prefix, pad_len, compound_string)
    convert_with_prefix = (str_prefix.blank? && pad_len.nil? ? false : true)
    str_split_all = compound_string.split(",")
    str_vals = []; str_ranges = []; error = [];

    for str_val in str_split_all
      str_val = str_val.to_s.delete(' ')

      if convert_with_prefix  # reformat/add prefix and push to array
        case str_val
          when /^(\d+)$/ # digits only
            str_vals.push(barcode_format(str_prefix, pad_len, str_val))
          when /^(\d+)\-(\d+)$/ # has range of digits
            str_ranges.push([barcode_format(str_prefix, pad_len, $1), barcode_format(str_prefix, pad_len, $2)])
          else error << str_val + ' is unexpected value'
        end # case

      else
        case str_val
          when /^(\w+)$/ #alphanumeric only (not a range)
            str_vals.push(str_val)
          when /^(\d+)-(\d+)$/ #numeric range, convert to integer so that SQL search will work correctly
            str_ranges.push([$1.to_i, $2.to_i])
          when /^(\w+)-(\w+)$/ #alphanumeric range, leave as is
            str_ranges.push([$1, $2])
          else  error << str_val + ' is unexpected value'
        end #case
      end #if convert_with_prefix
    end # for

    return str_vals, str_ranges, error
  end

  def barcode_format(str_prefix, pad_len, sstring)
    return(str_prefix + "%0#{pad_len}d" % sstring.to_i)
  end

  def sql_compound_condition(sql_fld, fld_vals, fld_ranges)
    where_select = []; where_values = [];

    if !fld_vals.empty?
      where_select.push("#{sql_fld} IN (?)")
      where_values.push(fld_vals)
    end

    if !fld_ranges.empty?
      for fld_range in fld_ranges
        where_select.push("#{sql_fld} BETWEEN ? AND ?")
        where_values.push(fld_range[0])
        where_values.push(fld_range[1])
      end
    end

    where_clause = (where_select.size > 0 ? ['(' + where_select.join(' OR ') + ')'] : [])
    return where_clause, where_values
  end

  def sql_condition(input_val)
    if input_val.is_a?(Array)
      conditional = ' IN (?)'
    elsif input_val.is_a?(String)
      conditional = (input_val[0,4] == 'LIKE'? ' LIKE ?' : ' = ?')
    else
      conditional = ' = ?'
    end 
    return conditional
  end
  
  def sql_value(input_val)
    if input_val.is_a?(String) && input_val[0,4] == 'LIKE'
      input_val = ['%',input_val[5..-1],'%'].join
    # Hack to deal with Rails 3.2 'error', adding additional blank value to array when multi-item select uses 'Include Blank' value
    elsif input_val.is_a?(Array) && input_val.size > 1
      input_val.shift if input_val[0].blank?
    end
    return input_val
  end
  
  def sql_conditions_for_range(where_select, where_values, from_val, to_val, db_fld)
    if !from_val.blank? && !to_val.blank?
      where_select.push "#{db_fld} BETWEEN ? AND ?"
      where_values.push(from_val, to_val) 
    elsif !from_val.blank? # To value is null or blank
      where_select.push("#{db_fld} >= ?")
      where_values.push(from_val)
    elsif !to_val.blank? # From value is null or blank
      where_select.push("(#{db_fld} IS NULL OR #{db_fld} <= ?)")
      where_values.push(to_val)
    end  
    return where_select, where_values 
  end
  
  def sql_conditions_for_date_range(where_select, where_values, params, db_fld)
    if !params[:from_date].blank? && !params[:to_date].blank?
      where_select.push "#{db_fld} BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY)"
      where_values.push(params[:from_date], params[:to_date])
    elsif !params[:from_date].blank? # To Date is null or blank
      where_select.push("#{db_fld} >= ?")
      where_values.push(params[:from_date])
    elsif !params[:to_date].blank? # From Date is null or blank
      where_select.push("(#{db_fld} IS NULL OR #{db_fld} <= DATE_ADD(?, INTERVAL 1 DAY))")
      where_values.push(params[:to_date])
    end  
    return where_select, where_values 
  end

  def sql_where(condition_array)
    # Handle change from Rails 2.3 to Rails 3.2 to turn conditions into individual parameters vs array
    if condition_array.nil? || condition_array.empty?
      return nil
    else
      return *condition_array
    end
  end
  
  def email_value(email_hash, email_type, deliver_site)
    site_and_type = [deliver_site.downcase, email_type].join('_')
    return (email_hash[site_and_type.to_sym].nil? ? email_hash[email_type.to_sym] : email_hash[site_and_type.to_sym])
  end
  
protected
  def set_current_user
    @user = User.find_by_id(session[:user])
    if @user
      User.current_user = @user
    end
  end
  
  def log_user_action
    user_login = (User.current_user.nil? ? 'nil' : User.current_user.login)
    logger.info("<**User:  #{user_login} **> Controller/Action: #{self.controller_name}/#{self.action_name}" +
                  " IP: " + request.remote_ip + " Date/Time: " + Time.now.strftime("%Y-%m-%d %H:%M:%S"))
    UserLog.add_entry(self, User.current_user, request.remote_ip)
  end
end
