# Internal: Add 'recurring_subscription' tag to shopify customer object
# (found via recharge sub.customer_id -> recharge cust.shopify_customer_id ->
# shopify cust.id) if shopify customer object does not contain
# 'recurring_subscription' tag already.
class CustomerUpdatewSub
  def initialize(sub_id, sub)
    @sub_id = sub_id
    @sub = sub
    my_token = ENV['RECHARGE_ACTIVE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def tag_customer
    shop_url = "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    # find shopify customer associated with subscription_id passed
    # in from recharge webhook to subscriptions#create endpoint
    begin
    retries ||= 0
    my_customer = get_shopify_customer(@sub)
    my_tags = my_customer.tags.split(",")
    my_tags.map! {|x| x.strip}
    if my_tags.include?('recurring_subscription') || my_tags.include?('Inactive Subscriber')
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
  	retry if retries < 2
   end
  end

  def get_shopify_customer(sub)
    my_url = "https://api.rechargeapps.com/customers/#{sub["customer_id"]}"
    response = HTTParty.get(my_url, :headers => @my_header)
    my_response = JSON.parse(response.body)
    #recharge_cust is now a hash with string keys
    recharge_cust = my_response['customer']
    Resque.logger.info "Found recharge customer #{recharge_cust['id']}"

    shop_url = "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    sleep 5
    shopify_cust = ShopifyAPI::Customer.find(recharge_cust["shopify_customer_id"])
    Resque.logger.info "customer shopify id: #{recharge_cust["shopify_customer_id"]}"

    return shopify_cust
  end

end
