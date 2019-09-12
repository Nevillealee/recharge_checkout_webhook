class ShopifyCustomerTag
  @queue = :update_w_sub
  def self.perform(sub_id, obj)
    Resque.logger = Logger.new("#{Rails.root}/log/recurring_tag.log")
    Resque.logger.info "Job ShopifyCustomerTag started"
    CustomerUpdatewSub.new(sub_id, obj).tag_customer
  end
end
