module Exceptions
  class InvalidLinkError < StandardError; end
  class LimitExceedError < StandardError; end
  class InviteCodeRequiredError < StandardError; end
end
