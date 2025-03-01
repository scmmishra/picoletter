module Helpers
  module Auth
    def sign_in(user)
      session = user.sessions.create!
      cookies.signed[:session_token] = { value: session.token, httponly: true, same_site: :lax }
      allow(Current).to receive(:user).and_return(user)
    end

    def sign_out
      cookies.delete(:session_token)
      allow(Current).to receive(:user).and_return(nil)
    end
  end
end
