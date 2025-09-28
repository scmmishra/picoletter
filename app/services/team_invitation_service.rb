class TeamInvitationService
  class AlreadyMemberError < StandardError; end
  class ExistingInvitationError < StandardError; end
  class ValidationError < StandardError; end

  attr_reader :newsletter, :email, :role, :invited_by, :original_email

  def initialize(newsletter:, email:, role:, invited_by:)
    @newsletter = newsletter
    @original_email = email
    @email = normalize_email(email)
    @role = role
    @invited_by = invited_by
  end

  def call
    raise AlreadyMemberError, "#{original_email} is already a member of this newsletter." if existing_member?
    raise ExistingInvitationError, "An invitation has already been sent to #{original_email}." if existing_invitation?

    invitation = build_invitation

    unless invitation.save
      raise ValidationError, "Failed to send invitation: #{invitation.errors.full_messages.join(', ')}"
    end

    send_invitation_email(invitation)
    invitation
  end

  private

  def existing_member?
    newsletter.memberships
               .joins(:user)
               .where("LOWER(users.email) = ?", email)
               .exists?
  end

  def existing_invitation?
    newsletter.invitations
               .pending
               .for_email(email)
               .exists?
  end

  def build_invitation
    newsletter.invitations.build(
      email: email,
      role: role,
      invited_by: invited_by
    )
  end

  def send_invitation_email(invitation)
    InvitationMailer.with(invitation: invitation).team_invitation.deliver_now
  end

  def normalize_email(value)
    value.to_s.strip.downcase
  end
end
