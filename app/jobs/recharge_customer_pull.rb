class RechargeCustomerPull
  @queue = :recharge
  def self.perform
    GetDataAPI.save_recharge_customers
  end
end
