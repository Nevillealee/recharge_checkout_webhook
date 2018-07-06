class ShopifyCustomerPull
  # queue instance variable required
  # name can be whatever you want
  @queue = :shopify
  # perform method has to take same arguements
  # as enqueue method calling this worker
  def self.perform
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.info "Job ShopifyCustomerPull started"
    GetDataAPI.save_all_shopify_customers
  end
end
