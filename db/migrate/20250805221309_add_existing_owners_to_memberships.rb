class AddExistingOwnersToMemberships < ActiveRecord::Migration[8.0]
  def up
    # Add all existing newsletter owners as administrator memberships
    Newsletter.find_each do |newsletter|
      Membership.create!(
        user: newsletter.user,
        newsletter: newsletter,
        role: :administrator
      )
    end
  end

  def down
    # Remove all administrator memberships that match newsletter owners
    Newsletter.find_each do |newsletter|
      Membership.where(
        user: newsletter.user,
        newsletter: newsletter,
        role: :administrator
      ).destroy_all
    end
  end
end
