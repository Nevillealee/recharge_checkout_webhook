# Internal: Using subscription or customer json recieved from recharge,
# remove 'recurring_subscription' tag from matching shopify customer object
# if customer no longer has an active subscription.
class UnTagger
  def initialize(id, type, obj)
    @my_id = id
    @id_type = type
    @recharge_obj = obj
    # TODO(Neville): change to active env
    my_token = ENV['RECHARGE_STAGING_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def remove
    # TODO(Neville): change to active env
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    if @id_type == 'subscription'
      # link subscription_id to its recharge customer.
      # returns a hash array
      recharge_sub = @recharge_obj
      puts recharge_obj.inspect
      recharge_customer = RechargeCustomer.find_by_sql(
        "SELECT rc.* FROM recharge_customers rc
        INNER JOIN recharge_subscriptions rs
        ON rc.id = CAST(rs.customer_id AS BIGINT)
        WHERE rs.id = '#{@my_id}';"
      )
      cust_id = recharge_customer[0]["id"]
      Resque.logger.info "(subscription)found recharge customer id: #{cust_id}"
      shopify_id = recharge_customer[0]["shopify_customer_id"]
      my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{cust_id}&status=ACTIVE"
      response = HTTParty.get(my_url, :headers => @my_header)
      my_response = JSON.parse(response.body)
      # subs_array is now an array of hashes with string keys
      subs_array = my_response['subscriptions']


      if subs_array.size <= 0
        sleep 5
        my_shopify_cust = ShopifyAPI::Customer.find(shopify_id)
        my_tags = my_shopify_cust.tags.split(",")
        my_tags.map! {|x| x.strip}
        Resque.logger.info "tags before: #{my_shopify_cust.tags.inspect}"
        my_tags.delete_if {|x| x.include?('recurring_subscription')}
        my_shopify_cust.tags = my_tags.join(",")
        my_shopify_cust.save
        Resque.logger.info "tags after: #{my_shopify_cust.tags.inspect}"
        Resque.logger.info "tag removed"
      else
        Resque.logger.info subs_array.inspect
        Resque.logger.info "tags will not be removed, customer has #{subs_array.size} other ACTIVE subscriptions"
      end

    elsif @id_type == 'customer'
      begin
        Resque.logger.info '(customer) block reached in Untagger worker'
        # id_type of customer refers to recharge customer object id
        recharge_url = "https://api.rechargeapps.com/customers/#{@my_id}"
        recharge_response = HTTParty.get(recharge_url, :headers => @my_header)
        parsed_recharge_response = JSON.parse(recharge_response.body)
        recharge_cust = parsed_recharge_response['customer']


        Resque.logger.info "shopify customer id: #{recharge_cust['shopify_customer_id']}"
        my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{@my_id}&status=ACTIVE"
        response = HTTParty.get(my_url, :headers => @my_header)
        my_response = JSON.parse(response.body)
        subs_array = my_response['subscriptions']
        Resque.logger.info "subs_array =  #{subs_array.inspect}"
        Resque.logger.info "number of subscriptions: #{subs_array.size}"
      # only remove tags if customer deactivated AND doesnt have other active subs
        if subs_array.size <= 0
          changes_made = false
          sleep 5
          my_shopify_cust = ShopifyAPI::Customer.find(recharge_cust['shopify_customer_id'])
          my_tags = my_shopify_cust.tags.split(",")
          Resque.logger.info "tags before: #{my_shopify_cust.tags.inspect}"
          my_tags.map! {|x| x.strip}

          my_tags.each do |x|
            if x.include?('recurring_subscription')
              my_tags.delete(x)
              changes_made = true
            end
          end

          if changes_made
            my_shopify_cust.tags = my_tags.join(",")
            Resque.logger.info "changes made, tags after: #{my_shopify_cust.tags.inspect}"
            my_shopify_cust.save
          end
        end
      rescue => e
        Resque.logger.info "error: #{e.message}"
      end
    else
      Resque.logger.info "type: '#{@id_type}' parameter not recognized.."
    end
  end

end
