require 'rails_helper'

RSpec.describe PrepaidOrderHandler, type: :model do
  context "When 3month_nocharge key does not exist" do
    it "adds the 3month_nocharge kv to Order.line_items" do
      new_line_items = PrepaidOrderHandler.new(1234567, BASE_ITEMS).start
      expect(new_line_items).to eq(LABELED_ITEMS)
    end
  end
  context "When 3month_nocharge key does exist" do
    it "does nothing to Order.line_items" do
      new_line_items = PrepaidOrderHandler.new(1234567, LABELED_ITEMS).start
      expect(new_line_items).to eq(LABELED_ITEMS)
    end
  end
end
