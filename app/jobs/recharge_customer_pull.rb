class RechargeCustomerPull
  @queue = :recharge
  def self.perform
    CustomerAPI.save_recharge_customers
  end
end
