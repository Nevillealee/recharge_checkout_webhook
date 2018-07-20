class ShopifyCustomerPull
  @queue = :shopify
  def self.perform
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.info "Job ShopifyCustomerPull started"
    GetDataAPI.save_all_shopify_customers
  end
end
