class ShopifyCustomerTag
  @queue = :shopify
  
  def self.perform(sub_id)
    CustomerUpdatewSub.new(sub_id).tag_customer
  end
end
