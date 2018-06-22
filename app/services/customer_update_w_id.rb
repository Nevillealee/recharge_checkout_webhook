class CustomerUpdatewID
  def initialize(shopify_id)
    @my_id = shopify_id
  end

  def tag_customer
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    api_cust_obj = ShopifyAPI::Customer.find(@my_id)
    api_tags = api_cust_obj.tags.delete(' ').split(",")
    Resque.logger.info "#{api_tags.inspect}"

    if api_tags.include?("recurring_subscription")
      Resque.logger.info "customer doesnt need to be tagged"
      Resque.logger.info "customer doesnt need to be tagged"
    else
      Resque.logger.info "customer tags before: #{api_cust_obj.tags}"
      api_tags << 'recurring_subscription'
      api_cust_obj.tags = api_tags.join(", ")
      Resque.logger.info "customer tags after: #{api_cust_obj.tags}"
      api_cust_obj.save
    end
  end


end
