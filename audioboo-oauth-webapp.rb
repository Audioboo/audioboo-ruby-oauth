#!/usr/bin/env ruby
require 'bundler/setup'
require 'oauth2'
require 'sinatra'
require 'json'
require_relative './consumer_key'

# This minimal web app uses OAuth2 Authorization code grant to fetch an access token from audioboom.com
client = OAuth2::Client.new(
  KEY,
  SECRET,
  site: 'https://api.audioboom.com',
  authorize_url: "/authorize",
  token_url: "/token"
) do |faraday|
  faraday.request :multipart
  faraday.request :url_encoded
  faraday.adapter Faraday.default_adapter
end

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'notvery'

get '/' do
  "<form action=/oauth_start method=POST><button>Get Audioboo access token</button></form>"
end

# Redirect the user to the Audioboo site to authorize access for your service.
post '/oauth_start' do
  authorization_grant_url = client.auth_code.authorize_url(
    redirect_uri: "#{request.base_url}/oauth_callback",
    state: {_crsf: session[:csrf]}
  )
  redirect to(authorization_grant_url)
end

# Handle the callback from the audioboo API, after the user has authorized access.
get '/oauth_callback' do
  auth_code = params[:code]
  access_token = client.auth_code.get_token(auth_code)
  session[:access_token] = access_token.to_hash

  # Now that you've got an access token you can use it to make authenticated calls to the Audioboo API.
  # See https://github.com/audioboo/api/blob/master/sections/reference_index.md for
  # all the other calls you can make.
  redirect to('/show_audioboo_account')
end

get '/show_audioboo_account' do
  access_token = OAuth2::AccessToken.from_hash(client, session[:access_token])
  account_response = access_token.get('/account')
  account_info = JSON.parse(account_response.body)
  image_url = account_info['body']['user']['urls']['image']
  <<-HTML
    <h1>Got access token!</h1>
    <p>#{access_token.token} </p>
    <hr/>
    <form action='/upload' enctype='multipart/form-data' method=POST>
      Want to upload an audio file?
      <input type=file name=audio_file>
      <input type=submit value=Upload>
    </form>
    <hr/>
    <h2>Your audioboo account:</h2>
    <pre>#{CGI.escape_html JSON.pretty_generate(account_info) }</pre>
    <img src="#{image_url}"/>
  HTML
end

post "/upload" do
  access_token = OAuth2::AccessToken.from_hash(client, session[:access_token])
  local_file = params['audio_file']
  file_upload = Faraday::UploadIO.new local_file[:tempfile], local_file[:type], local_file[:filename]
  clip_params = {
    'audio_clip[title]' => 'my first post',
    'audio_clip[uploaded_data]' => file_upload
  }
  response = access_token.post('/account/audio_clips', body: clip_params)
  response.status.to_s
end
