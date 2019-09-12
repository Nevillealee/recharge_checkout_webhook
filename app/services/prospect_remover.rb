# Internal: Using customer  json received from ReCharge,
# remove 'prospect' tag from matching Shopify customer object
# once customer has created an Order (charge sucessfully processed)
class ProspectRemover
  def initialize(id)
    @recharge_cust_id = id
    my_token = ENV['RECHARGE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def start
    begin
    # get customer object from Recharge
    my_url = "https://api.rechargeapps.com/customers/#{@recharge_cust_id}"
    response = HTTParty.get(my_url, :headers => @my_header)
    my_response = JSON.parse(response.body)
    recharge_cust = my_response['customer']
    Resque.logger.info "shopify customer id: #{recharge_cust['shopify_customer_id']}"

    changes_made = false
    sleep 5

    # get shopify customer object tags
    shopify_cust = ShopifyAPI::Customer.find(recharge_cust['shopify_customer_id'])
    my_tags = shopify_cust.tags.split(",")
    my_tags.map! {|x| x.strip}
    Resque.logger.info "Shopify Customer api tags before: #{shopify_cust.tags.inspect}"

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
