# Internal: Using subscription or customer json recieved from recharge,
# remove 'recurring_subscription' tag from matching shopify customer object
# if customer no longer has an active subscription.
class UnTagger
  def initialize(id, type, obj)
    @my_id = id
    @id_type = type
    @recharge_obj = obj

    my_token = ENV['RECHARGE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def remove
    if @id_type == 'subscription'
      # link subscription_id to its recharge customer.
      # returns a hash array
      recharge_sub = @recharge_obj
      recharge_customer = Customer.find_by_customer_id(recharge_sub['customer_id'])
      Resque.logger.info "(subscription)found recharge customer id: #{recharge_customer.customer_id}"
      my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{recharge_customer.customer_id}&status=ACTIVE"
      response = HTTParty.get(my_url, :headers => @my_header)
      my_response = JSON.parse(response.body)
      # subs_array is now an array of hashes with string keys
      active_subs = my_response['subscriptions']
      puts "ACTIVE SUB RESPONSE: #{active_subs.inspect}"
      if active_subs.size <= 0
        sleep 5
        my_shopify_cust = ShopifyAPI::Customer.find(recharge_customer.shopify_customer_id)
        my_tags = my_shopify_cust.tags.split(",")
        my_tags.map! {|x| x.strip}
        Resque.logger.info "tags before: #{my_shopify_cust.tags.inspect}"
        my_tags.delete_if {|x| x.include?('recurring_subscription')}
        my_shopify_cust.tags = my_tags.join(",")
        my_shopify_cust.save
        Resque.logger.info "tags after: #{my_shopify_cust.tags.inspect}"
        Resque.logger.info "tag removed"
      else
        Resque.logger.info active_subs.inspect
        Resque.logger.info "tags will not be removed, customer has #{active_subs.size} other ACTIVE subscriptions"
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
      # TODO(Neville): replace line 68 with recurring status method
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
