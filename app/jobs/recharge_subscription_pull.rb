class RechargeSubscriptionPull
  @queue = :recharge
  def self.perform
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.info "Job RechargeSubscriptionPull started"
    GetDataAPI.save_recharge_subscriptions
  end
end
