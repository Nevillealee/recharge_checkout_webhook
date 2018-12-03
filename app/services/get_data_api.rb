# Internal: Various methods useful for pulling
# the latest data from both shopify and recharge apis.
# All methods are module methods and should be called
# on the GetDataAPI module.
module GetDataAPI
  SHOPIFY_CUSTOMERS = []
  RECHARGE_CUSTOMERS = []
  RECHARGE_SUBS = []
  my_token = ENV['RECHARGE_ACTIVE_TOKEN']
  @my_header = {
    "X-Recharge-Access-Token" => my_token
  }

  def self.save_all_shopify_customers
    all_customers = init_all_shopify_customers
    size = all_customers.size
    progressbar = ProgressBar.create(
    title: 'Progess',
    starting_at: 0,
    total: size,
    format: '%t: %p%%  |%B|')

    all_customers.each do |shopify_cust|
    begin
      ShopifyCustomer.create(
      id: shopify_cust['id'],
      accepts_marketing: shopify_cust['accepts_marketing'],
      addresses: shopify_cust['addresses'],
      default_address: shopify_cust['default_address'],
      email: shopify_cust['email'],
      first_name: shopify_cust['first_name'],
      last_name: shopify_cust['last_name'],
      last_order_id: shopify_cust['last_order_id'],
      multipass_identifier: shopify_cust['multipass_identifier'],
      note: shopify_cust['note'],
      orders_count: shopify_cust['orders_count'],
      phone: shopify_cust['phone'],
      state: shopify_cust['state'],
      tags: shopify_cust['tags'],
      tax_exempt: shopify_cust['tax_exempt'],
      total_spent: shopify_cust['total_spent'],
      verified_email: shopify_cust['verified_email'],
      created_at: shopify_cust['created_at'],
      updated_at: shopify_cust['updated_at']
      )
    rescue StandardError => e
      puts e.inspect
        puts "error with #{shopify_cust['first_name']} #{shopify_cust['last_name']}"
        next
      end
      p "saved #{shopify_cust['id']}"
      progressbar.increment
    end
    puts 'shopify customers saved to db..'
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
# Internal: Remove propsect tag from Active Subscribers on ellie active.
#
# Examples
#
#   rake remove_prospect
#   #=> 4716400210
#       found ambermarie.design@gmail.com
#       tags before: "Active Subscriber, newsletter, password page, prospect, recurring_subscription"
#       tags after: "Active Subscriber,newsletter,password page,recurring_subscription"
#       D, [2018-10-19T10:14:28.982108 #4399] DEBUG -- :    (0.2ms)  BEGIN
#       D, [2018-10-19T10:14:28.982219 #4399] DEBUG -- :   ↳ app/services/get_data_api.rb:144
#
# Returns the local shopify_customer with fixed = true
  def self.remove_prospect
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    keyword1 = "prospect"
    keyword2 = "Active Subscriber"
    query1 = "%#{keyword1}%"
    query2 = "%#{keyword2}%"
    mistagged_customers = ShopifyCustomer.where("tags LIKE ? AND tags LIKE ? AND fixed = ?", query1, query2, false)
    puts "we have #{mistagged_customers.size} customers tagged incorrectly"

    mistagged_customers.each do |cust|
      puts cust.id
      shopify_api_throttle
      my_shopify_cust = ShopifyAPI::Customer.find(cust.id)
      puts "found #{my_shopify_cust.email}"
      my_tags = my_shopify_cust.tags.split(",")
      my_tags.map! {|x| x.strip}
      puts "tags before: #{my_shopify_cust.tags.inspect}"
      my_tags.delete_if {|x| x.include?('prospect')}
      my_shopify_cust.tags = my_tags.join(",")
      puts "tags after: #{my_shopify_cust.tags.inspect}"
      begin
        my_shopify_cust.save
        cust.fixed = true
        cust.save!
      rescue StandardError => e
        puts "e.inspect"
        sleep 5
        next
      end

    end
  end

  private
  def self.shopify_api_throttle
    # ShopifyAPI::Base.site =
    #   "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
      return if ShopifyAPI.credit_left > 5
      put "api limit reached sleeping 10.."
      sleep 10
  end
  def self.init_recharge_customers
    ReCharge.api_key ="#{ENV['RECHARGE_ACTIVE_TOKEN']}"
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
  def self.init_all_shopify_customers
    customer_array = []
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    shopify_customer_count = ShopifyAPI::Customer.count
    nb_pages = (shopify_customer_count / 250.0).ceil
    puts "We have #{shopify_customer_count} Shopify customers to pull"

    1.upto(nb_pages) do |page|
      ellie_active_url =
        "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/customers.json?limit=250&page=#{page}"
        shopify_api_throttle
      @parsed_response = HTTParty.get(ellie_active_url)
      customer_array.push(@parsed_response['customers'])
      p "shopify customers set #{page}/#{nb_pages} loaded"
      # sleep 3
    end
    p 'all shopify customers initialized'
    customer_array.flatten!
    return customer_array
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
