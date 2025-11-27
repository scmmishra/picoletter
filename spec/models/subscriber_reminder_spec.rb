require "rails_helper"

RSpec.describe SubscriberReminder, type: :model do
  it { should belong_to(:subscriber) }
  it { should validate_presence_of(:kind) }
  it { should define_enum_for(:kind).with_values(manual: 0, automatic: 1) }
end
