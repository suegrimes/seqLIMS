class ItemsController < ApplicationController
  before_filter :dropdowns, :only => [:new_query, :new, :edit]
  protect_from_forgery :except => :populate_items
  
  autocomplete :item, :catalog_nr
  autocomplete :item, :company_name
  autocomplete :item, :item_description
  
  def new_query
    @item_query = ItemQuery.new(:from_date => (Date.today - 1.month).beginning_of_month,
                                :to_date   =>  Date.today)
  end
  
  def list_selected
    @item_query = ItemQuery.new(params[:item_query])
    
    if @item_query.valid?
      condition_array = define_conditions(params)
      items_all = Item.find_all_by_date(condition_array)
      items_notordered = items_all.reject{|item| item.ordered?}
     
      # Eliminate items from array, based on order status if specified
      if params[:item_query][:item_status] && params[:item_query][:item_status] != 'All'
        @items = items_notordered                        if params[:item_query][:item_status] == 'NotOrdered'
        @items = items_all.reject{|item| !item.ordered?} if params[:item_query][:item_status] == 'Ordered' 
      else
        @items = items_all
      end
    
      # Check whether any potential items to order, and if so, populate company drop-down
      @items_to_order = items_notordered.size
      @companies = list_companies_from_items(items_notordered)
      render :action => :index
      
    else
      dropdowns
      render :action => :new_query
    end
  end
  
  def list_unordered_items
    @items = Item.find_all_unordered
    @items_to_order = @items.size
    @companies = list_companies_from_items(@items)
    render :action => :index
  end
  
  # GET /items
  def index
    @items = Item.find_all_by_date
    
    items_notordered = @items.reject{|item| item.ordered?}
    @items_to_order = items_notordered.size
    @companies = list_companies_from_items(items_notordered)  
  end

  # GET /items/1
  def show
    @item = Item.find(params[:id])
  end

  # GET /items/new
  def new
    requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @item_default = Item.new(:requester_name => requester)
  end
  
  def populate_items
    @items = []
    params[:nr_items] ||= 3
    
    0.upto(params[:nr_items].to_i - 1) do |i|
      @items[i] = Item.new(params[:item_default])
    end    

    respond_to do |format|
      format.js
    end

  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
  end

  # POST /items
  def create         
    # items should ideally be in an array params[:items], but workaround to have the auto-populate after the auto-complete
    # on the multi-item form, with html tags identified => item params are instead in params[:items_1], params[:items_2] etc.
    
    # Loop around params[:items_1] to params[:items_n], merge defaults into each item, and create array
    @items = []
    for i in 0..25 do
      this_item = params['items_' + i.to_s]
      break if this_item.nil?
      next  if (param_blank?(this_item[:item_description]) && param_blank?(this_item[:catalog_nr]))
      @items.push(Item.new(params[:item_default].merge(this_item))) # merge in this direction so that company name is not overridden by default value
    end
    
    #@email_create_orders = email_value(EMAIL_CREATE, 'orders', @items[0].deliver_site.downcase)
    #@email_delivery_orders = email_value(EMAIL_DELIVERY, 'orders', @items[0].deliver_site.downcase)
    #render :action => 'debug'
    
    if @items.all?(&:valid?) 
      @items.each(&:save!)
      flash[:notice] = 'Items were successfully saved.'
      
      # item successfully saved => send emails as indicated by EMAIL_CREATE and EMAIL_DELIVERY flags
      email_create_orders = email_value(EMAIL_CREATE, 'orders', @items[0].deliver_site)
      email_delivery_orders = email_value(EMAIL_DELIVERY, 'orders', @items[0].deliver_site)
      
      email = OrderMailer.new_items(@items, current_user) unless email_create_orders == 'NoEmail'
      if email_delivery_orders == 'Debug'
        render(:text => "<pre>" + email.encoded + "</pre>")
      else
        email.deliver! if email_delivery_orders == 'Deliver'
        redirect_to :action => 'list_unordered_items'
      end
         
    else
      reload_defaults(params[:item_default])
      flash.now[:error] = 'One or more errors - no items saved, please enter all required fields'
      render :action => 'new'
    end 

  end

  # PUT /items/1
  def update
    params[:item][:company_name] ||= params[:other_company]
    @item = Item.find(params[:id])

    if @item.update_attributes(params[:item])
      flash[:notice] = 'Item was successfully updated.'
      redirect_to(@item) 
    else
      dropdowns
      render :action => "edit", :other_company => params[:other_company]
    end
  end

  # DELETE /items/1
  def destroy
    @item = Item.find(params[:id])
    @item.destroy

    redirect_to :action => 'new_query'
  end
  
  def autocomplete_item_catalog_nr
    @items = Item.find_all_unique(["catalog_nr LIKE ?", params[:term] + '%'])
    list = @items.map {|i| Hash[ id: i.id, label: i.catalog_nr, name: i.catalog_nr, company_name: i.company_name, desc: i.item_description, price: i.item_price ]}
    render json: list
  end
  
  def autocomplete_item_item_description
    @items = Item.find_all_unique(["item_description LIKE ?", params[:term] + '%'])
    list = @items.map {|i| Hash[ id: i.id, label: i.item_description, name: i.item_description, cat_nr: i.catalog_nr, company_name: i.company_name, price: i.item_price]}
    render json: list
  end
  
  def autocomplete_item_company_name
    @items = Item.find_all_unique(["company_name LIKE ?", params[:term] + '%'])
    @items = @items.uniq { |h| h[:company_name] }
    list = @items.map {|i| Hash[ id: i.id, label: i.company_name, name: i.company_name]}
    render json: list
  end
  
  def update_fields
    params[:i] ||= 0
    if params[:catalog_nr]
      @item = Item.find_by_catalog_nr(params[:catalog_nr])
    elsif params[:item_description]
      @item = Item.find_by_item_description(params[:item_description]) 
    end
    
    if @item.nil?
      render :nothing => true
    else
      render :update do |page|
        page['items_' + params[:i] + '_catalog_nr'].value        = @item.catalog_nr
        page['items_' + params[:i] + '_item_description'].value  = @item.item_description
        page['items_' + params[:i] + '_company_name'].value      = @item.company_name
        page['items_' + params[:i] + '_chemical_flag'].value     = @item.chemical_flag
        page['items_' + params[:i] + '_item_size'].value         = @item.item_size
        page['items_' + params[:i] + '_item_price'].value        = @item.item_price
       end
    end
  end
  
protected
  def dropdowns
    items_all  = Item.all
    @companies = list_companies_from_items(items_all)
    @requestors = items_all.collect(&:requester_name).sort.uniq
    @researchers = Researcher.populate_dropdown
    @grant_nrs = Category.populate_dropdown_for_category('grants')
  end
  
  def reload_defaults(item_params)
    dropdowns
    @item_default    = Item.new(item_params)
  end

  def list_companies_from_items(items)
    companies_from_items = items.collect(&:company_name).sort.uniq
    return ["CWA"] | companies_from_items | ["Other"]
  end
  
   def define_conditions(params)
    @sql_params = {}
    params[:item_query].each do |attr, val|
      @sql_params[attr.to_sym] = val if !val.blank? && ItemQuery::ITEM_FLDS.include?("#{attr}")
    end
    
    @where_select = []; @where_values = []
    @sql_params.each do |attr, val|
      if !param_blank?(val)
        @where_select.push("items.#{attr}" + sql_condition(val))
        @where_values.push(sql_value(val))
      end
    end

    date_fld = 'items.created_at'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:item_query], date_fld)
    
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end
  
end
