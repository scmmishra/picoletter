class TeamInvitationService
  class AlreadyMemberError < StandardError; end
  class ExistingInvitationError < StandardError; end
  class ValidationError < StandardError; end

  attr_reader :newsletter, :email, :role, :invited_by

  def initialize(newsletter:, email:, role:, invited_by:)
    @newsletter = newsletter
    @email = email
    @role = role
    @invited_by = invited_by
  end

  def call
    raise AlreadyMemberError, "#{email} is already a member of this newsletter." if existing_member?
    raise ExistingInvitationError, "An invitation has already been sent to #{email}." if existing_invitation?

    invitation = build_invitation

    unless invitation.save
      raise ValidationError, "Failed to send invitation: #{invitation.errors.full_messages.join(', ')}"
    end

    send_invitation_email(invitation)
    invitation
  end

  private

  def existing_member?
    newsletter.memberships.joins(:user).exists?(users: { email: email })
  end

  def existing_invitation?
    newsletter.invitations.pending.exists?(email: email)
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
end
