class IndexTagsController < ApplicationController
  
  def edit
    @index_tag = IndexTag.find(params[:id])
  end

  def update
    @index_tag = IndexTag.find(params[:id])

    if @index_tag.update_attributes(params[:index_tag])
      flash[:notice] = "Index #{@index_tag.index_code} was successfully updated."
      redirect_to(adapter_path(:id => @index_tag.adapter_id))
    else
      render :action => "edit"
    end
  end

  def xxx_index
    #@adapters = IndexTag.find(:all, :select => "runtype_adapter, COUNT(id)", :group => "runtype_adapter")
    @adapters = Adapter.includes(:index_tags).select('adapters.runtype_adapter, COUNT(index_tags.id)').where("adapters.runtype_adapter <> 'Multiple'").group('adapters.runtype_adapter, adapters.index_read').all
    index_tags = IndexTag.includes(:adapter).all
    sorted_tags = index_tags.sort_by {|tag| [tag.tag_ctr, tag.adapter_name, tag.index_read]}
    @index_tags = sorted_tags.group_by {|tag| tag.tag_ctr}
    render :debug
  end



end
