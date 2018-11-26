# Internal: Various methods useful for pulling
# the latest data from both shopify and recharge apis.
# All methods are module methods and should be called
# on the GetDataAPI module.

module GetDataAPI
  SHOPIFY_CUSTOMERS = []
  RECHARGE_CUSTOMERS = []
  RECHARGE_SUBS = []
  my_token = ENV['RECHARGE_STAGING_TOKEN']
  @sleep_recharge = ENV['RECHARGE_SLEEP_TIME']

  @my_header = {
    "X-Recharge-Access-Token" => my_token
  }
  @my_change_charge_header = {
    "X-Recharge-Access-Token" => my_token,
    "Accept" => "application/json",
    "Content-Type" =>"application/json"
  }
  @uri = URI.parse(ENV['DATABASE_URL'])
  @conn = PG.connect(@uri.hostname, @uri.port, nil, nil, @uri.path[1..-1], @uri.user, @uri.password)
  @shopify_base_site = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"

  def self.handle_shopify_customers(option)
    params = {"option_value" => option, "connection" => @uri, "shopify_base" => @shopify_base_site, "sleep_shopify" => @sleep_shopify}
    if option == "full_pull"
      Resque.logger.info "Doing full pull of shopify customers"
      #delete tables and do full pull
      Resque.logger.debug "handle_shopify_customers uri: #{@uri.inspect}"
      Resque.enqueue(PullShopifyCustomer, params)
    elsif option == "yesterday"
      Resque.logger.info "Doing partial pull of shopify customers since yesterday"
      #params = {"option_value" => option, "connection" => @uri}
      Resque.enqueue(PullShopifyCustomer, params)
    else
      Resque.logger.error "sorry, cannot understand option #{option}, doing nothing."
    end
  end

  def self.save_recharge_customers
    init_recharge_customers

    RECHARGE_CUSTOMERS.each do |cust|
      puts "#{cust.inspect}"
      RechargeCustomer.create(
        id: cust.id,
        customer_hash: cust.hash,
        shopify_customer_id: cust.shopify_customer_id,
        email: cust.email,
        created_at: cust.created_at,
        updated_at: cust.updated_at,
        first_name: cust.first_name,
        last_name: cust.last_name,
        billing_address1: cust.billing_address1,
        billing_address2: cust.billing_address2,
        billing_zip: cust.billing_zip,
        billing_city: cust.billing_city,
        billing_company: cust.billing_company,
        billing_province: cust.billing_province,
        billing_country: cust.billing_country,
        billing_phone: cust.billing_phone,
        processor_type: cust.processor_type,
        status: cust.status
      )
    end
    puts "recharge customers saved to db"
  end

  def self.save_recharge_subscriptions
    init_recharge_subs
    RECHARGE_SUBS.each do |s|
      puts "saving #{s['id']}"
      begin
      RechargeSubscription.create(
        id: s['id'],
        address_id: s['address_id'],
        customer_id: s['customer_id'],
        created_at: s['created_at'],
        updated_at: s['updated_at'],
        next_charge_scheduled_at: s['next_charge_scheduled_at'],
        cancelled_at: s['cancelled_at'],
        product_title: s['product_title'],
        price: s['price'],
        quantity: s['quantity'],
        status: s['status'],
        shopify_variant_id: s['shopify_variant_id'],
        sku: s['sku'],
        order_interval_frequency: s['order_interval_frequency'],
        order_day_of_month: s['order_day_of_month'],
        order_day_of_week: s['order_day_of_week'],
        properties: s['properties'],
        expire_after_specfic_number_of_charges: s['expire_after_specfic_number_of_charges']
      )
      rescue
        puts "error with subscription id #{s['id']}"
        next
      end
    end
    puts "recharge subscriptions saved to db.."
  end

  private
  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
      return if ShopifyAPI.credit_left > 5
      put "api limit reached sleeping 10.."
      sleep 10
  end

  def self.init_recharge_customers
    ReCharge.api_key ="#{ENV['RECHARGE_STAGING_TOKEN']}"
    customer_count = Recharge::Customer.count
    nb_pages = (customer_count / 250.0).ceil

    1.upto(nb_pages) do |current_page| # throttling conditon
      customers = ReCharge::Customer.list(:page => current_page, :limit => 250)
      RECHARGE_CUSTOMERS.push(customers)
      p "recharge customer set #{current_page}/#{nb_pages} loaded"
    end
    p 'recharge customers initialized'
    RECHARGE_CUSTOMERS.flatten!
  end

  def self.init_recharge_subs
    response = HTTParty.get("https://api.rechargeapps.com/subscriptions/count", :headers => @my_header)
    my_response = JSON.parse(response.body)
    my_count = my_response['count'].to_i
    nb_pages = (my_count / 250.0).ceil

    1.upto(nb_pages) do |page|
      subs =  HTTParty.get("https://api.rechargeapps.com/subscriptions?limit=250&page=#{page}", :headers => @my_header)
      local_sub = subs['subscriptions']
      local_sub.each do |s|
        RECHARGE_SUBS.push(s)
      end
      p "recharge subscription set #{page}/#{nb_pages} loaded"
      sleep 3
    end
    p 'recharge subscriptions initialized'
  end

end
