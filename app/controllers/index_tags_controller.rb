class IndexTagsController < ApplicationController
  
  def index
    #@adapters = IndexTag.find(:all, :select => "runtype_adapter, COUNT(id)", :group => "runtype_adapter")
    @adapters = IndexTag.select('runtype_adapter, COUNT(id)').group(:runtype_adapter).all
    index_tags = IndexTag.all
    sorted_tags = index_tags.sort_by {|tag| [tag.tag_ctr, tag.runtype_adapter]}
    @index_tags = sorted_tags.group_by {|tag| tag.tag_ctr}
  end

end
