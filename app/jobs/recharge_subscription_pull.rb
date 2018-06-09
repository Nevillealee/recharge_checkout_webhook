class RechargeSubscriptionPull
  @queue = :recharge
  def self.perform
    GetDataAPI.save_recharge_subscriptions
  end
end
