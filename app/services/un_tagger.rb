class UnTagger
  def initialize(id, type)
    @my_id = id
    @id_type = type
    my_token = ENV['RECHARGE_ACTIVE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def remove
    if @id_type == 'subscription'
      # TODO(Neville Lee) change shop url env keys to ellie active
      shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      # link subscription_id to its recharge customer
      # returns an hash array
      recharge_customer = RechargeCustomer.find_by_sql(
        "SELECT * FROM recharge_customers rc
        INNER JOIN recharge_subscriptions rs
        ON rc.id = CAST(rs.customer_id AS BIGINT)
        WHERE rs.id = '#{@my_id}';"
      )
      shopify_id = recharge_customer[0]["shopify_customer_id"]
      cust_id = recharge_customer[0]["id"]
      my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{cust_id}&status=ACTIVE"
      response = HTTParty.get(my_url, :headers => @my_header)
      my_response = JSON.parse(response.body)
      # subs_array is now an array of hashes with string keys
      subs_array = my_response['subscriptions']

      if subs_array.size !> 0
        my_shopify_cust = ShopifyAPI::Customer.find(shopify_id)
        my_tags = my_shopify_cust.tags.split(",")
        puts "tags before: #{my_shopify_cust.tags}"
        my_tags.delete_if {|x| x == 'recurring_subscription'}
        puts "tags after: #{my_shopify_cust.tags}"
        my_shopify_cust.tags = my_tags
        # my_shopify_cust.save
      end
    elsif @id_type == 'customer'

    else
      puts "type parameter not recognized, received: #{@id_type}"
    end
  end


end
