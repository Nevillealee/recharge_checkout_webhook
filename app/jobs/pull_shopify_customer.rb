class PullShopifyCustomer
  @queue = :data
  extend EllieHelper
  def self.perform(params)
    Resque.logger = Logger.new("#{Rails.root}/log/shopify_pull_resque.log",  10, 1024000)
    Resque.logger.info "Job PullShopifyCustomer started"
    Resque.logger.debug "PullShopifyCustomer#perform params: #{params.inspect}"
    get_shopify_customers_full(params)
  end

end
