class UnTagger
  def initialize(id, type, obj)
    @my_id = id
    @id_type = type
    @cust = obj
    my_token = ENV['RECHARGE_STAGING_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def remove
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    if @id_type == 'subscription'
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
      Resque.logger.info "(subscription)found recharge customer id: #{cust_id}"
      shopify_id = recharge_customer[0]["shopify_customer_id"]
      my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{cust_id}&status=ACTIVE"
      response = HTTParty.get(my_url, :headers => @my_header)
      my_response = JSON.parse(response.body)
      # subs_array is now an array of hashes with string keys
      subs_array = my_response['subscriptions']


      if subs_array.size <= 0
        my_shopify_cust = ShopifyAPI::Customer.find(shopify_id)
        my_tags = my_shopify_cust.tags.split(",")
        Resque.logger.info "tags before: #{my_shopify_cust.tags}"
        my_tags.delete_if {|x| x.include?('recurring_subscription')}
        my_shopify_cust.tags = my_tags.join(",")
        Resque.logger.info "tags after: #{my_shopify_cust.tags}"
        my_shopify_cust.save
        Resque.logger.info "tag removed"
      else
        Resque.logger.info subs_array.inspect
        Resque.logger.info "tags will not be removed, customer has #{subs_array.size} other ACTIVE subscriptions"
      end

    elsif @id_type == 'customer'
      begin
        retries ||= 0
        Resque.logger.info '(customer) block reached in Untagger worker'
        # id_type of customer refers to recharge customer object id
        shopify_cust = RechargeCustomer.find("#{@my_id}")
        Resque.logger.info "shopify customer id: #{shopify_cust.shopify_customer_id}"
        my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{@my_id}&status=ACTIVE"
        response = HTTParty.get(my_url, :headers => @my_header)
        my_response = JSON.parse(response.body)
        subs_array = my_response['subscriptions']
        Resque.logger.info "subs_array =  #{subs_array.inspect}"
        Resque.logger.info "number of subscriptions: #{subs_array.size}"
      # only remove tags if customer deactivated AND doesnt have other active subs
        if subs_array.size <= 0
          my_shopify_cust = ShopifyAPI::Customer.find(shopify_cust.shopify_customer_id)
          my_tags = my_shopify_cust.tags.split(",")
          Resque.logger.info "tags before: #{my_shopify_cust.tags}"
          my_tags.delete_if {|x| x.include?('recurring_subscription')}
          my_shopify_cust.tags = my_tags.join(",")
          Resque.logger.info "tags after: #{my_shopify_cust.tags}"
          my_shopify_cust.save
        end
      rescue => e
        Resque.logger.info "error: #{e.message}"
        Resque.logger.info "Adding new customer to db"
        add_customer(@cust)
        retries += 1
        retry if retries < 3
      end
    else
      Resque.logger.info "type: '#{@id_type}' parameter not recognized.."
    end
  end

  def add_customer(my_cust)
    RechargeCustomer.create(
      id: @my_id,
      customer_hash: my_cust['customer_hash'],
      shopify_customer_id: my_cust['shopify_customer_id'],
      email: my_cust['email'],
      created_at: my_cust['created_at'],
      updated_at: my_cust['updated_at'],
      first_name: my_cust['first_name'],
      last_name: my_cust['last_name'],
      billing_address1: my_cust['billing_address1'],
      billing_address2: my_cust['billing_address2'],
      billing_zip: my_cust['billing_zip'],
      billing_city: my_cust['billing_city'],
      billing_company: my_cust['billing_company'],
      billing_province: my_cust['billing_province'],
      billing_country: my_cust['billing_country'],
      billing_phone: my_cust['billing_phone'],
      processor_type: my_cust['processor_type'],
      status: my_cust['status']
    )
  end

end
