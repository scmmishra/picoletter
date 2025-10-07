module Authorizable
  extend ActiveSupport::Concern

  PERMISSION_MAP = {
    general: {
      read: [ :owner, :administrator, :editor ],
      write: [ :owner, :administrator ]
    },
    design: {
      read: [ :owner, :administrator, :editor ],
      write: [ :owner, :administrator ]
    },
    sending: {
      read: [ :owner, :administrator ],
      write: [ :owner, :administrator ]
    },
    billing: {
      read: [ :owner ],
      write: [ :owner ]
    },
    profile: {
      read: [ :owner, :administrator, :editor ],
      write: [ :owner, :administrator, :editor ]
    },
    embedding: {
      read: [ :owner, :administrator, :editor ],
      write: [ :owner, :administrator ]
    },
    team: {
      read: [ :owner, :administrator, :editor ],
      write: [ :owner, :administrator ]
    }
  }.freeze

  def can_access?(permission, access_type = :read)
    permission_config = PERMISSION_MAP[permission]
    return false unless permission_config

    allowed_roles = permission_config[access_type]
    return false unless allowed_roles

    user_role = user_role(Current.user)
    allowed_roles.include?(user_role)
  end

  def can_read?(permission)
    can_access?(permission, :read)
  end

  def can_write?(permission)
    can_access?(permission, :write)
  end
end
