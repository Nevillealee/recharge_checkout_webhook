class ShopifyCustomerTag
  @queue = :update_w_sub
  def self.perform(sub_id, obj)
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.info "Job ShopifyCustomerTag started"
    CustomerUpdatewSub.new(sub_id, obj).tag_customer
  end
end
