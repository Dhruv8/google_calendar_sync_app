# spec/controllers/session_controller_spec.rb
require 'rails_helper'

RSpec.describe SessionController, type: :controller do
  describe 'GET #google_login' do
    it 'redirects to Google OAuth URL with proper parameters' do
      client_id = ENV['GOOGLE_CLIENT_ID']
      redirect_uri = ENV['GOOGLE_REDIRECT_URI']
      scope = 'https://www.googleapis.com/auth/calendar.events'
      oauth_url = "https://accounts.google.com/o/oauth2/auth?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=#{scope}&response_type=code&access_type=offline&prompt=consent"

      get :google_login
      expect(response).to redirect_to(oauth_url)
    end
  end

  describe 'GET #callback' do
    let(:code) { 'authorization_code' }
    let(:access_token) { 'access_token' }
    let(:refresh_token) { 'refresh_token' }

    before do
      stub_request(:post, 'https://oauth2.googleapis.com/token')
        .with(
          body: {
            code: code,
            client_id: ENV['GOOGLE_CLIENT_ID'],
            client_secret: ENV['GOOGLE_CLIENT_SECRET'],
            redirect_uri: ENV['GOOGLE_REDIRECT_URI'],
            grant_type: 'authorization_code'
          }
        )
        .to_return(status: 200, body: {
          access_token: access_token,
          refresh_token: refresh_token
        }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'successfully exchanges code for tokens and redirects to calendar index' do
      get :callback, params: { code: code }
      expect(response).to redirect_to(calender_index_path)
    end

    it 'redirects to root path on failed token exchange' do
      stub_request(:post, 'https://oauth2.googleapis.com/token')
        .to_return(status: 400, body: { error: 'invalid_grant' }.to_json, headers: { 'Content-Type' => 'application/json' })

      get :callback, params: { code: code }
      expect(response).to redirect_to(root_path)
    end
  end
end
