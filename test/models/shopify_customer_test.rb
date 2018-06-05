require 'test_helper'

class ShopifyCustomerTest < ActiveSupport::TestCase
  test "customer exists" do
    cust = ShopifyCustomer.new
    assert cust.save
  end
end
