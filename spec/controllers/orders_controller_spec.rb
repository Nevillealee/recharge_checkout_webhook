require 'rails_helper'

RSpec.describe OrdersController, type: :controller do

  context "Recharge webhook event fires" do
    before do
      ResqueSpec.reset!
    end
    it "sanitizers order params" do
      request.headers['X-Recharge-Topic'] = "order/created"
      post :create, :params => { :order =>
        { :id => 1234567, :is_prepaid => 1, :status => "QUEUED", :customer_id => 11111111 }
      }
      expect(response).to have_http_status(200)
    end
    it "enqueues QueuedOrderLabel job" do
      request.headers['X-Recharge-Topic'] = "order/created"
      post :create, :params => { :order =>
        { :id => 1234567, :is_prepaid => 1, :status => "QUEUED", :customer_id => 11111111 }
      }
      expect(QueuedOrderLabel).to have_queued("1234567").in(:queued_order_label)
    end
  end
end
