# Takes subscription_id to match shopify customer
# before updating shopify with the customers new tags

class CustomerUpdatewSub
  def initialize(sub_id, sub)
    @sub_id = sub_id
    @sub = sub
    my_token = ENV['RECHARGE_STAGING_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def tag_customer
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    # find shopify customer associated with subscription_id passed
    # in from recharge webhook to subscriptions#create endpoint
    begin
    retries ||= 0
    my_customer = get_shopify_customer(@sub)

    my_tags = my_customer.tags.split(",")
    my_tags.map! {|x| x.strip}
    if my_tags.include?('recurring_subscription')
      Resque.logger.info my_tags.inspect
      Resque.logger.info "customer doesnt need to be tagged"
    else
      Resque.logger.info "making api call in order to tag customer.."
      shopify_cust_obj = ShopifyAPI::Customer.find(my_customer.id)
      Resque.logger.info "here what shopifys api returned from ID: #{shopify_cust_obj.id}"
      my_tags << "recurring_subscription"
      # shopify wont accept tag string values without space AND comma delimited tokens!
      Resque.logger.info "old shopify customer object tags: #{shopify_cust_obj.tags}"
      shopify_cust_obj.tags = my_tags.join(",")
      shopify_cust_obj.save
      Resque.logger.info "new shopify customer object tags: #{shopify_cust_obj.tags}"
    end

    rescue => e
      retries += 1
      Resque.logger.info "ERROR: #{e.message}"
      Resque.logger.info "Attempt ##{retries}/3"
      # add_subscription(@sub)
  	retry if retries < 2
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

  def get_shopify_customer(sub)
    Resque.logger.info "calling apis to get shopify customer from sub data"
    my_url = "https://api.rechargeapps.com/customers/#{sub["customer_id"]}"
    response = HTTParty.get(my_url, :headers => @my_header)
    my_response = JSON.parse(response.body)
    #recharge_cust is now a hash with string keys
    recharge_cust = my_response['customer']
    Resque.logger.info "Found recharge customer #{recharge_cust['id']}"

    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    shopify_cust = ShopifyAPI::Customer.find(recharge_cust["shopify_customer_id"])
    return shopify_cust
  end

end
