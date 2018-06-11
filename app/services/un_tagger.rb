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
    shop_url = "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    if @id_type == 'subscription'
      puts 'subscription block reached in Untagger worker'
      # TODO(Neville Lee) change shop url env keys to ellie active

      # link subscription_id to its recharge customer.
      # returns a hash array
      recharge_customer = RechargeCustomer.find_by_sql(
        "SELECT rc.* FROM recharge_customers rc
        INNER JOIN recharge_subscriptions rs
        ON rc.id = CAST(rs.customer_id AS BIGINT)
        WHERE rs.id = '#{@my_id}';"
      )
      cust_id = recharge_customer[0]["id"]
      puts "found recharge customer id: #{cust_id}"
      shopify_id = recharge_customer[0]["shopify_customer_id"]
      my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{cust_id}&status=ACTIVE"
      response = HTTParty.get(my_url, :headers => @my_header)
      my_response = JSON.parse(response.body)
      # subs_array is now an array of hashes with string keys
      subs_array = my_response['subscriptions']


      if subs_array.size <= 0
        my_shopify_cust = ShopifyAPI::Customer.find(shopify_id)
        my_tags = my_shopify_cust.tags.split(",")
        puts "tags before: #{my_shopify_cust.tags}"
        my_tags.delete_if {|x| x == 'recurring_subscription'}
        my_shopify_cust.tags = my_tags
        puts "tags after: #{my_shopify_cust.tags}"
        # my_shopify_cust.save
      else
        puts subs_array.inspect
        puts "tags will not removed, customer has #{subs_array.size} other ACTIVE subscriptions"
      end

    elsif @id_type == 'customer'
      puts 'customer block reached in Untagger worker'
      # id_type of customer refers to recharge customer object id
      shopify_cust = RechargeCustomer.find("#{@my_id}")
      puts "shopify customer id: #{shopify_cust.shopify_customer_id}"
      my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{@my_id}&status=ACTIVE"
      response = HTTParty.get(my_url, :headers => @my_header)
      my_response = JSON.parse(response.body)
      subs_array = my_response['subscriptions']
      puts"subs_array =  #{subs_array.inspect}"
      puts "number of subscriptions: #{subs_array.size}"
      # only remove tags if customer deactivated AND doesnt have other active subs
        if subs_array.size <= 0
          my_shopify_cust = ShopifyAPI::Customer.find(shopify_cust.shopify_customer_id)
          my_tags = my_shopify_cust.tags.split(",")
          puts "tags before: #{my_shopify_cust.tags}"
          my_tags.delete_if {|x| x == 'recurring_subscription'}
          my_shopify_cust.tags = my_tags
          puts "tags after: #{my_shopify_cust.tags}"
          # my_shopify_cust.save
        end
    else
      puts "type: '#{@id_type}' parameter not recognized.."
    end
  end
end
