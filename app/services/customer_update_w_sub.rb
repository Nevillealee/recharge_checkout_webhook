# Takes subscription_id to match shopify customer
# before updating shopify with the customers new tags

class CustomerUpdatewSub
  def initialize(sub_id)
    @sub_id = sub_id
  end

  def tag_customer
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
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
    puts "cant find subscription id: #{@sub_id} linked to a shopify customer object" if my_customer == []
    my_tags = my_customer[0]["tags"].split(",")
    if my_tags.include?('recurring_subscription')
      puts my_tags.inspect
      puts "customer doesnt need to be tagged"
    else
      puts "making api call in order to tag customer.."
      shopify_cust_obj = ShopifyAPI::Customer.find(my_customer[0]["id"])
      puts "here what shopifys api returned from ID: #{my_customer[0]["id"]}"
      # puts shopify_cust_obj.inspect
      my_tags << "recurring_subscription"
      new_tags = my_tags.join(", ")
      puts "old shopify customer object tags: #{shopify_cust_obj.tags}"
      shopify_cust_obj.tags = new_tags
      puts "new shopify customer object tags: #{shopify_cust_obj.tags}"
      # shopify_cust_obj.save
    end
  end


end
