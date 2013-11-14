module ActiveRecordExtension

  extend ActiveSupport::Concern

  ################################################################################################
  # Add instance methods here as:                                                                #
  #  def foo                                                                                     #
  #    "foo"                                                                                     #
  #  end                                                                                         #
  ################################################################################################

  module ClassMethods
  ###############################################################################################
  # sql_where:                                                                                  #
  # From array of SQL where conditions, return nil if array is empty, or individual parameters  #
  #   if array is populated                                                                     #
  ###############################################################################################
    def sql_where(condition_array)
      if condition_array.nil? || condition_array.empty?
        return nil
      else
        return *condition_array
      end
    end
  end

ActiveRecord::Base.send(:include, ActiveRecordExtension)

end