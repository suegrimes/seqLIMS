class IndexTagsController < ApplicationController
  
  def index
    #@adapters = IndexTag.find(:all, :select => "runtype_adapter, COUNT(id)", :group => "runtype_adapter")
    @adapters = Adapter.includes(:index_tags).select('adapters.runtype_adapter, COUNT(index_tags.id)').where("adapters.runtype_adapter <> 'Multiple'").group('adapters.runtype_adapter').all
    index_tags = IndexTag.all
    sorted_tags = index_tags.sort_by {|tag| [tag.tag_ctr, tag.runtype_adapter]}
    @index_tags = sorted_tags.group_by {|tag| tag.tag_ctr}
  end

end
