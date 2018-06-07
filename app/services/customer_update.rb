class CustomerUpdate
  def initialize(sub_id)
    @sub_id = sub_id
  end

  def link_sub_to_shopify_customer
    shop_url = "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    # find shopify customer associated with subscription_id passed
    # in from recharge webhook to subscriptions#create endpoint
    my_customer = ShopifyCustomer.find_by_sql(
      "select * from recharge_subscriptions rs
      INNER JOIN recharge_customers rc
      ON CAST(rs.customer_id AS BIGINT) = rc.id
      INNER JOIN shopify_customers sc
      ON CAST(rc.shopify_customer_id AS BIGINT) = sc.id
      where rs.id = '#{@sub_id}';"
    )
    my_tags = my_customer[0]["tags"].split(",")
    if my_tags.include?('recurring_subscription')
      puts "customer doesnt need to be tagged"
    else
      puts "we are now making api call to tag customer"
      shopify_cust_obj = ShopifyAPI::Customer.find(my_customer[0]["id"])
      puts "here what shopifys api returned from ID: #{my_customer[0]["id"]}"
      # puts shopify_cust_obj.inspect
      my_tags << "recurring_subscription"
      new_tags = my_tags.join(", ")
      puts "old shopify customer object tags: #{shopify_cust_obj.tags}"
      shopify_cust_obj.tags = new_tags
      # shopify_cust_obj.save
      puts "new shopify customer object tags: #{shopify_cust_obj.tags}"
    end
  end


end

# select * from recharge_subscriptions rs
# INNER JOIN recharge_customers rc ON CAST(rs.customer_id AS BIGINT) = rc.id
# INNER JOIN shopify_customers sc ON CAST(rc.shopify_customer_id AS BIGINT) = sc.id
# where rs.id = '16841217';
