# == Schema Information
#
# Table name: protocols
#
#  id                        :integer(4)      not null, primary key
#  protocol_name             :string(50)
#  protocol_abbrev           :string(25)
#  protocol_version          :string(10)
#  protocol_type             :string(1)
#  protocol_steps            :text
#  protocol_file             :string(255)
#  protocol_subfile_or_sheet :string(50)
#  vendor                    :string(50)
#  catalog_nr                :string(50)
#  lot_nr                    :string(50)
#  reference                 :string(100)
#  comments                  :string(255)
#  created_at                :datetime
#  updated_at                :timestamp       not null
#

class Protocol < ActiveRecord::Base
  #PROTOCOL_TYPES = {'Dissection' => 'D', 'Extraction' => 'E', 'Molecular Assay' => 'M', 'Library Prep' => 'L',
  #                 'Analysis' => 'A'}
  PROTOCOL_TYPES      = {'Extraction' => 'E', 'Library Prep' => 'L', 'Molecular Assay' => 'M'}
  PROTOCOL_TYPE_NAMES = PROTOCOL_TYPES.invert
                    
  def self.find_for_protocol_type(protocol_type)
    protocol_array = protocol_type.to_a
    self.find(:all, :conditions => ['protocol_type IN (?)', protocol_array],
                    :order      => 'protocol_name')
  end
  
  def name_ver
    [protocol_name, protocol_version].join('/')
  end
  
  def molecule_type
    if protocol_type != 'M'
      return nil
    else
      return (protocol_name.include?('Expresssion') ? 'R' : 'D')
    end
  end

end
