# Internal: add 'recurring_subscription' tag to shopify customer object
# matched by shopify_customer_id sent from recharge through its customer
# object if shopify customer object does not contain tag already.
class CustomerUpdatewID
  def initialize(shopify_id)
    @my_id = shopify_id
  end

  def tag_customer
    shop_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    sleep 5
    api_cust_obj = ShopifyAPI::Customer.find(@my_id)
    api_tags = api_cust_obj.tags.split(",")
    Resque.logger.info "unaltered tags from shopify: #{api_tags.inspect}"
    api_tags.map! {|x| x.strip}

    if api_tags.include?("recurring_subscription")
      Resque.logger.info "customer doesnt need to be tagged"
    else
      Resque.logger.info "customer tags before: #{api_cust_obj.tags.inspect}"
      api_tags << "recurring_subscription"
      api_cust_obj.tags = api_tags.join(",")
      api_cust_obj.save
      Resque.logger.info "customer tags after save: #{api_cust_obj.tags.inspect}"
    end
    # 
    # begin
    #   if !(ShopifyCustomer.where(id: @my_id).exists?)
    #     Resque.logger.info "customer does not exist in database yet.."
    #     add_customer(api_cust_obj)
    #   end
    # rescue => e
    #   Resque.logger.info "#{e.message}"
    # end

  end

  def add_customer(cust)
    ShopifyCustomer.create(
      id: cust.id,
      accepts_marketing: cust.accepts_marketing,
      addresses: cust.addresses,
      default_address: cust.default_address,
      email: cust.email,
      first_name: cust.first_name,
      last_name: cust.last_name,
      # last_order_id: cust.last_order_id,
      # metafield: cust.metafield,
      # multipass_identifier: cust.multipass_identifier,
      # note: cust.note,
      # orders_count: cust.orders_count,
      phone: cust.phone,
      state: cust.state,
      tags: cust.tags,
      # tax_exempt: cust.tax_exempt,
      total_spent: cust.total_spent,
      verified_email: cust.verified_email,
      created_at: cust.created_at,
      updated_at: cust.updated_at
    )
    Resque.logger.info "customer saved to db"
  end

end
