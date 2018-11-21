# Internal: add 'recurring_subscription' tag to shopify customer object
# matched by shopify_customer_id sent from recharge through its customer
# object if shopify customer object does not contain tag already.
class CustomerUpdatewID
  def initialize(shopify_id)
    @my_id = shopify_id
  end

  def tag_customer
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    sleep 5
    ShopifyAPI::Base.site = shop_url
    api_cust_obj = ShopifyAPI::Customer.find(@my_id)
    api_tags = api_cust_obj.tags.split(",")
    Resque.logger.info "unaltered tags from shopify: #{api_tags.inspect}"
    api_tags.map! {|x| x.strip}

    if api_tags.include?("recurring_subscription") || api_tags.include?("Inactive Subscriber")
      Resque.logger.info "customer doesnt need to be tagged"
    else
      Resque.logger.info "customer tags before: #{api_cust_obj.tags.inspect}"
      api_tags << "recurring_subscription"
      api_cust_obj.tags = api_tags.join(",")
      api_cust_obj.save
      Resque.logger.info "customer tags after save: #{api_cust_obj.tags.inspect}"
    end
  end

end
