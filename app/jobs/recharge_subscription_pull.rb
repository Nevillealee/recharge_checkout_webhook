class RechargeSubscriptionPull
  @queue = :recharge
  def self.perform
    CustomerAPI.save_recharge_subscriptions
  end
end
