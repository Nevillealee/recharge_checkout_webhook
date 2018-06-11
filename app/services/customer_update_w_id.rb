class CustomerUpdatewID
  def initialize(shopify_id)
    @my_id = shopify_id
  end

  def tag_customer
    shop_url = "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    api_cust_obj = ShopifyAPI::Customer.find(@my_id)
    api_tags = api_cust_obj.tags.split(",")

    if api_tags.include?('recurring_subscription')
      puts "customer doesnt need to be tagged"
    else
      puts "customer tags before: #{api_cust_obj.tags}"
      api_tags << 'recurring_subscription'
      api_cust_obj.tags = api_tags.join(", ")
      puts "customer tags after: #{api_cust_obj.tags}"
      # api_cust_obj.save
    end
  end


end
