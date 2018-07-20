class NewShopifyCustomerTag
  @queue = :shopify
  def self.perform(shopify_id)
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.info "Job NewShopifyCustomerTag started"
    CustomerUpdatewID.new(shopify_id).tag_customer
  end
end
