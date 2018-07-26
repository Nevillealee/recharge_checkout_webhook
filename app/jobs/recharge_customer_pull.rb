class RechargeCustomerPull
  @queue = :data
  def self.perform
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.info "Job RechargeCustomerPull started"
    GetDataAPI.save_recharge_customers
  end
end
