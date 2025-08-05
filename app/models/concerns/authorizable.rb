module Authorizable
  extend ActiveSupport::Concern

  PERMISSION_MAP = {
    general: [ :owner, :administrator ],
    design: [ :owner, :administrator ],
    sending: [ :owner, :administrator ],
    billing: [ :owner, :administrator ],
    embedding: [ :owner, :administrator ],
    profile: [ :owner, :administrator, :editor ]
  }.freeze

  def can_access?(permission)
    allowed_roles = PERMISSION_MAP[permission]
    return false unless allowed_roles

    user_role = user_role(Current.user)
    allowed_roles.include?(user_role)
  end
end
