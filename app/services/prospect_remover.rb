# Internal: Using subscription or customer json recieved from recharge,
# remove 'recurring_subscription' tag from matching shopify customer object
# if customer no longer has an active subscription.
class ProspectRemover
  def initialize(id)
    @recharge_cust_id = id
    my_token = ENV['RECHARGE_STAGING_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def start
    begin
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    my_url = "https://api.rechargeapps.com/customers/#{@recharge_cust_id}"
    response = HTTParty.get(my_url, :headers => @my_header)
    my_response = JSON.parse(response.body)
    recharge_cust = my_response['customer']
    Resque.logger.info "shopify customer id: #{recharge_cust['shopify_customer_id']}"

    changes_made = false
    sleep 5
    shopify_cust = ShopifyAPI::Customer.find(recharge_cust['shopify_customer_id'])
    my_tags = shopify_cust.tags.split(",")
    my_tags.map! {|x| x.strip}
    Resque.logger.info "tags before: #{shopify_cust.tags.inspect}"

    my_tags.each do |x|
      if x.include?('prospect')
        my_tags.delete(x)
        changes_made = true
      end
    end

    if changes_made
      shopify_cust.tags = my_tags.join(",")
      shopify_cust.save
      Resque.logger.info "changes made, tags after: #{shopify_cust.tags.inspect}"
    else
      Resque.logger.info "prospect tag not found in: #{shopify_cust.tags.inspect}"
    end

    rescue => e
      Resque.logger.info "error: #{e.message}"
    end
  end


end
