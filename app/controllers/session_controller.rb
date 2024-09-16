
class SessionController < ApplicationController
  def google_login
    client_id = ENV["GOOGLE_CLIENT_ID"]
    redirect_uri = ENV["GOOGLE_REDIRECT_URI"]
    scope = "https://www.googleapis.com/auth/calendar.events"

    oauth_url = "https://accounts.google.com/o/oauth2/auth?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=#{scope}&response_type=code&access_type=offline&prompt=consent"

    # Redirect user to Google OAuth URL
    redirect_to oauth_url, allow_other_host: true
  end

  def callback
    code = params[:code]
    response = exchange_code_for_token(code)

    if response.success?
      token_data = JSON.parse(response.body)
      access_token = token_data["access_token"]
      refresh_token = token_data["refresh_token"]

      # Redirect to the calendars index page after successful login
      redirect_to calender_index_path
    else
      redirect_to root_path
    end
  end

  private

  def exchange_code_for_token(code)
    conn = Faraday.new(url: "https://oauth2.googleapis.com") do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end

    conn.post("/token", {
      code: code,
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"],
      grant_type: "authorization_code"
    })
  end
end
