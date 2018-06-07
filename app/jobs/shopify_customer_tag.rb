class ShopifyCustomerTag
  @queue = :shopify
  # perform method has to take same arguements
  # as enqueue method calling this worker
  def self.perform(id)
    CustomerUpdate.new(id).link_sub_to_shopify_customer
  end
end
