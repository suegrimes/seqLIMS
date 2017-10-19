class OrdersController < ApplicationController
  load_and_authorize_resource
  
  def new_query
    @item_query = ItemQuery.new(:from_date => (Date.today - 1.month).beginning_of_month,
                                :to_date   =>  Date.today)
  end
  
  def list_selected
    @item_query = ItemQuery.new(params[:item_query])
    
    if @item_query.valid?
      condition_array = define_conditions(params)
      @orders = Order.includes(:items).where(sql_where(condition_array)).order('date_ordered DESC')
      render :action => :index
      
    else
      render :action => :new_query
    end
  end
  
  # GET /orders
  # GET /orders.xml
  def index
    @orders = Order.includes(:items).order('date_ordered DESC').all
  end

  # GET /orders/1
  def show
    @order = Order.includes(:items).find(params[:id])
  end

  # GET /orders/1/edit
  def edit
    @order = Order.includes(:items).find(params[:id])
  end
  
  def edit_order_items
    @order = Order.includes(:items).find(params[:id])
  end

  # POST /orders
  # POST /orders.xml
  # Navigate to create orders, from items/list_unordered_items
  def create
    @order = Order.new(params[:order])

    if params[:item_id]  # only create order if at least one item checked
      @order.incl_chemicals = set_chemical_flag(params[:item_id]) if param_blank?(params[:order][:incl_chemicals])
      if @order.save
        Item.upd_orderid(@order.id, params[:item_id]) 
        flash[:notice] = 'Order was successfully created.'
        redirect_to(@order)
      else
        flash[:error] = 'Error creating order - please enter RPO/CWA, Company, Order Date, Requisition# and Chemicals'
        redirect_to notordered_path
      end
    else
      flash[:error] = 'Please check at least one item for this order'
      redirect_to notordered_path
    end
  end

  # PUT /orders/1
  # PUT /orders/1.xml
  def update
    @order = Order.find(params[:id])
    
    if @order.update_attributes(params[:order])
      if @order.order_received == 'P' && params[:item_upd] != 'Y'
        redirect_to :action => "edit_order_items", :id => @order.id
      else
        flash[:notice] = 'Order was successfully updated'
        qparams = {:item_query => {:deliver_site => '', :from_date => (Date.today - 1.month).beginning_of_month, :to_date => Date.today}}
        condition_array = define_conditions(qparams)
        @orders = Order.includes(:items).where(sql_where(condition_array)).order('date_ordered DESC')
        render :action => :index
      end
      
    else
      render :action => "edit" 
    end
    
  end

  # DELETE /orders/1
  # DELETE /orders/1.xml
  def destroy
    @order = Order.find(params[:id])
    @order.destroy

    respond_to do |format|
      format.html { redirect_to(orders_url) }
      format.xml  { head :ok }
    end
  end

protected
  def set_chemical_flag(item_id_list)
    items = Item.find_all_by_id(item_id_list)
    @_list ||= items.collect(&:chemical_flag)
    return (@_list.include?('Y')? 'Y' : 'N' )
  end
  
  def define_conditions(params)
    @where_select = []; @where_values = []
    
    if !param_blank?(params[:item_query][:deliver_site])
      @where_select.push("items.deliver_site" + sql_condition(params[:item_query][:deliver_site]))
      @where_values.push(params[:item_query][:deliver_site])
    end
      
    date_fld = 'orders.created_at'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:item_query], date_fld)
    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
        
    return sql_where_clause
  end
  
end
