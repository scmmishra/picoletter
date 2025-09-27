# == Schema Information
#
# Table name: invitations
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  email         :string           not null
#  role          :string           default("editor"), not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  invited_by_id :bigint           not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_invitations_on_invited_by_id  (invited_by_id)
#  index_invitations_on_newsletter_id  (newsletter_id)
#  index_invitations_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe ".for_email" do
    let!(:invitation) { create(:invitation, email: "person@example.com") }

    it "matches case-insensitively" do
      expect(Invitation.for_email("Person@Example.com")).to include(invitation)
    end

    it "returns empty relation when email blank" do
      expect(Invitation.for_email(nil)).to be_empty
    end
  end
end
