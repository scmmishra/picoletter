require 'rails_helper'

RSpec.describe Public::SubscribersController, type: :controller do
  let(:newsletter) { create(:newsletter) }
  let(:subscriber) { create(:subscriber, newsletter: newsletter) }

  before do
    allow(Newsletter).to receive(:from_slug).and_return(newsletter)
  end

  describe 'POST #embed_subscribe' do
    context 'when embed subscribe is enabled' do
      before do
        allow(AppConfig).to receive(:get).with("DISABLE_EMBED_SUBSCRIBE").and_return(false)
        allow(IPShieldService).to receive(:legit_ip?).and_return(true)
      end

      it 'creates a subscriber and redirects to almost there page' do
        expect(CreateSubscriberJob).to receive(:perform_now)
          .with(newsletter.id, 'test@example.com', 'Test User', 'embed', anything)

        post :embed_subscribe, params: {
          slug: newsletter.slug,
          email: 'test@example.com',
          name: 'Test User'
        }

        expect(response).to redirect_to(almost_there_path(newsletter.slug, email: 'test@example.com'))
      end
    end

    context 'when embed subscribe is disabled' do
      before do
        allow(AppConfig).to receive(:get).with("DISABLE_EMBED_SUBSCRIBE").and_return(true)
      end

      it 'returns forbidden' do
        post :embed_subscribe, params: { slug: newsletter.slug, email: 'test@example.com' }
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'POST #public_subscribe' do
    before do
      allow(IPShieldService).to receive(:legit_ip?).and_return(true)
    end

    it 'creates a subscriber and redirects to almost there page' do
      expect(CreateSubscriberJob).to receive(:perform_now)
        .with(newsletter.id, 'test@example.com', 'Test User', 'public', anything)

      post :public_subscribe, params: {
        slug: newsletter.slug,
        email: 'test@example.com',
        name: 'Test User'
      }

      expect(response).to redirect_to(almost_there_path(newsletter.slug, email: 'test@example.com'))
    end

    it 'handles invalid emails' do
      allow(CreateSubscriberJob).to receive(:perform_now).and_raise(StandardError.new("Invalid email"))
      allow(RorVsWild).to receive(:record_error)

      post :public_subscribe, params: { slug: newsletter.slug, email: 'invalid' }

      expect(response).to redirect_to(newsletter_path(newsletter.slug))
      expect(flash[:notice]).to match(/invalid email/)
    end
  end

  describe 'GET #almost_there' do
    it 'assigns provider info when email is present' do
      provider_service = instance_double(EmailInformationService,
        name: 'Gmail',
        search_url: 'https://mail.google.com/search')

      allow(EmailInformationService).to receive(:new).with('test@gmail.com').and_return(provider_service)

      get :almost_there, params: { slug: newsletter.slug, email: 'test@gmail.com' }

      email = controller.instance_variable_get('@email')
      provider = controller.instance_variable_get('@provider')
      search_url = controller.instance_variable_get('@search_url')

      expect(email).to eq('test@gmail.com')
      expect(provider).to eq(provider_service)
      expect(search_url).to eq('https://mail.google.com/search')
    end

    it 'does not assign provider when email is missing' do
      get :almost_there, params: { slug: newsletter.slug }

      email = controller.instance_variable_get('@email')
      provider = controller.instance_variable_get('@provider')

      expect(email).to be_nil
      expect(provider).to be_nil
    end
  end

  describe 'GET #unsubscribe' do
    it 'unsubscribes a subscriber with valid token' do
      token = subscriber.generate_token_for(:unsubscribe)

      expect {
        get :unsubscribe, params: { slug: newsletter.slug, token: token }
      }.to change { subscriber.reload.status }.from('unverified').to('unsubscribed')

      expect(subscriber.reload.unsubscribed_at).to be_present
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('unsubscribed')
    end

    it 'handles invalid token' do
      get :unsubscribe, params: { slug: newsletter.slug, token: 'invalid-token' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('invalid')
    end

    it 'handles POST requests' do
      token = subscriber.generate_token_for(:unsubscribe)

      post :unsubscribe, params: { slug: newsletter.slug, token: token }

      expect(subscriber.reload.status).to eq('unsubscribed')
      expect(response.content_type).to include('application/json')
      expect(JSON.parse(response.body)).to eq({ 'ok' => true })
    end
  end

  describe 'GET #confirm_subscriber' do
    it 'verifies a subscriber with valid token' do
      token = subscriber.generate_token_for(:confirmation)

      expect {
        get :confirm_subscriber, params: { slug: newsletter.slug, token: token }
      }.to change { subscriber.reload.status }.from('unverified').to('verified')

      expect(subscriber.reload.verified_at).to be_present
    end

    it 'handles invalid token' do
      get :confirm_subscriber, params: { slug: newsletter.slug, token: 'invalid-token' }

      expect(response).to have_http_status(:ok)
    end

    it 'handles expired token' do
      # Mock expired token by making find_by_token_for raise invalid signature
      allow(Subscriber).to receive(:find_by_token_for)
        .and_raise(ActiveSupport::MessageVerifier::InvalidSignature)

      get :confirm_subscriber, params: { slug: newsletter.slug, token: 'expired-token' }

      expect(response).to have_http_status(:ok)
    end
  end
end
