module Recurring
  # recurring ReCharge subscriptions wont have nil values for any of these sub attributes
  def is_recurring_sub?(sub)
    charge_int_freq = sub["charge_interval_frequency"]
    order_int_freq = sub["order_interval_frequency"]
    order_int_unit = sub["order_interval_unit"]
    Resque.logger.debug "Recharge Subscription RECURRING PROPERTY CHECK: \n"\
    "----->charge_interval_frequency: #{charge_int_freq}\n----->order_interval_frequency: "\
    "#{order_int_freq}\n----->order_interval_unit: #{order_int_unit}"
    return [charge_int_freq, order_int_freq, order_int_unit].all?
  end
end
