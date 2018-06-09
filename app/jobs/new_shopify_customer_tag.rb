class NewShopifyCustomerTag
  @queue = :shopify

  def self.perform(shopify_id)
    CustomerUpdatewID.new(shopify_id).tag_customer
  end
end
