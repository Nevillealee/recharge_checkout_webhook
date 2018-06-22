# Takes subscription_id to match shopify customer
# before updating shopify with the customers new tags

class CustomerUpdatewSub
  def initialize(sub_id, sub)
    @sub_id = sub_id
    @sub = sub
  end

  def tag_customer
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    # find shopify customer associated with subscription_id passed
    # in from recharge webhook to subscriptions#create endpoint
    begin
	retries ||= 0
    my_customer = ShopifyCustomer.find_by_sql(
      "select sc.* from recharge_subscriptions rs
      INNER JOIN recharge_customers rc
      ON CAST(rs.customer_id AS BIGINT) = rc.id
      INNER JOIN shopify_customers sc
      ON CAST(rc.shopify_customer_id AS BIGINT) = sc.id
      where rs.id = '#{@sub_id}';"
    )
    Resque.logger.info "cant find subscription id: #{@sub_id} linked to a shopify customer object" if my_customer == nil || my_customer == ""
    my_tags = my_customer[0]["tags"].split(",")
    if my_tags.include?('recurring_subscription')
      Resque.logger.info my_tags.inspect
      Resque.logger.info "customer doesnt need to be tagged"
    else
      Resque.logger.info "making api call in order to tag customer.."
      shopify_cust_obj = ShopifyAPI::Customer.find(my_customer[0]["id"])
      Resque.logger.info "here what shopifys api returned from ID: #{my_customer[0]["id"]}"
      # puts shopify_cust_obj.inspect
      my_tags << "recurring_subscription"
      new_tags = my_tags.join(", ")
      Resque.logger.info "old shopify customer object tags: #{shopify_cust_obj.tags}"
      shopify_cust_obj.tags = new_tags
      Resque.logger.info "new shopify customer object tags: #{shopify_cust_obj.tags}"
      shopify_cust_obj.save
    end

    rescue => e
	    Resque.logger.info "Adding subscription to db"
      Resque.logger.info "subscription not in database #{e.message}"
      add_subscription(@sub)
  	retry if (retries += 1) < 2
   end
  end

  def add_subscription(my_sub)
    RechargeSubscription.create(
       id: @sub_id,
       address_id: my_sub["address_id"],
       customer_id: my_sub["customer_id"],
       created_at: my_sub["created_at"],
       updated_at: my_sub["updated_at"],
       next_charge_scheduled_at: my_sub["next_charge_scheduled_at"],
       cancelled_at: my_sub["cancelled_at"],
       product_title: my_sub["product_title"],
       price: my_sub["price"],
       quantity: my_sub["quantity"],
       status: my_sub["status"],
       shopify_variant_id: my_sub["shopify_variant_id"],
       sku: my_sub["sku"],
       order_interval_frequency: my_sub["order_interval_frequency"],
       order_day_of_month: my_sub["order_day_of_month"],
       order_day_of_week: my_sub["order_day_of_week"],
       properties: my_sub["properties"],
       expire_after_specfic_number_of_charges: my_sub["expire_after_specfic_number_of_charges"]
    )
    Resque.logger.debug "Subscription saved to db"
  end

end
