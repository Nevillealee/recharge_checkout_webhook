# Internal: add 'recurring_subscription' tag to shopify customer object
# matched by shopify_customer_id sent from recharge through its customer
# object if shopify customer object does not contain tag already.
class CustomerUpdatewID
  Resque.logger = Logger.new("#{Rails.root}/log/resque_timeout.log")
  Resque.logger.level = Logger::DEBUG
  Resque.logger.datetime_format = '%F %Z %T '
  def initialize(shopify_id)
    @my_id = shopify_id
  end

  def tag_customer
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    sleep 5
    ShopifyAPI::Base.site = shop_url

    begin
    api_cust_obj = ShopifyAPI::Customer.find(@my_id)
    api_tags = api_cust_obj.tags.split(",")
    Rescue.logger.info "unaltered tags from shopify: #{api_tags.inspect}"
    api_tags.map! {|x| x.strip}

    if api_tags.include?("recurring_subscription") || api_tags.include?("Inactive Subscriber")
      Rescue.logger.info "customer doesnt need to be tagged"
    else
      Rescue.logger.info "customer tags before: #{api_cust_obj.tags.inspect}"
      api_tags << "recurring_subscription"
      api_cust_obj.tags = api_tags.join(",")
      api_cust_obj.save
      Rescue.logger.info "customer tags after save: #{api_cust_obj.tags.inspect}"
    end
    rescue ActiveResource::TimeoutError => e
      Rescue.logger.error e.message
      Rescue.logger.error api_cust_obj.inspect
    end
  end

end
