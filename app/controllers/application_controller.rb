# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

#include SslRequirement
  # Usage:
  # include SslRequirement should go after other important before_filters.  
  # Put the following in controllers to fine tune the ssl requirements:
  # ssl_required :action1_name, :action2_name - Non-SSL access will be redirected to SSL
  # ssl_allowed :action_name - This action will work either with or without SSL
  # other methods: SSL access will be redirected to non-SSL
  # https://github.com/rails/ssl_requirement

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoleRequirementSystem
  before_filter :login_required
 
  #Make current_user accessible from model (via User.current_user)
  before_filter :set_current_user
  before_filter :log_user_action
  
  rescue_from CanCan::AccessDenied do |exception|
    user_login = (current_user.nil? ? nil : current_user.login)
    flash[:error] = "Sorry #{user_login}, you are not authorized to access that page"
    redirect_to ''
  end
  # 
  require 'fastercsv'
  require 'calendar_date_select'

  helper :all # include all helpers, all the time
  #
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'a7fa20ae329c39ca9cb722a7173c224f'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password, :mrn
  
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
  
  def build_params_from_obj(obj, flds)
    params_hash = {}
    flds.each do |fld|
      params_hash.merge!(fld.to_sym => obj.send(fld))
    end
    return params_hash
  end
  
  def param_blank?(val)
    if val.nil?
      val_blank = true
    elsif val.is_a? Array
      val_blank = (val.length == 1 && val[0].blank? ? true : false )
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
