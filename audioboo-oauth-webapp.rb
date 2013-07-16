#!/usr/bin/env ruby
require 'bundler/setup'
require 'oauth'
require 'sinatra'
require 'json'
require 'net/http/post/multipart'
require_relative './consumer_key'

# This minimal web app uses OAuth to fetch a access token key & secret from audioboo.fm

def consumer
  OAuth::Consumer.new(KEY,SECRET, site: "http://api.audioboo.fm")
end
def access_token
  return nil unless session[:access_token]&&session[:access_secret]
  OAuth::AccessToken.new(consumer, session[:access_token], session[:access_secret])
end

enable :sessions
set :session_secret, "notvery"

get '/' do
  "<form action=/oauth_start method=POST><button>Get Audioboo access token</button></form>"
end


# Fetch a request token from the audioboo API, then redirect the user to the Audioboo site to authorize access for your service
post '/oauth_start' do
  request_token = consumer.get_request_token(oauth_callback: request.base_url + '/oauth_callback')
  # Save for later
  session[:request_token] = request_token.token
  session[:request_secret] = request_token.secret

  redirect to(request_token.authorize_url)
end


# Handle the callback from the audioboo API, after the user has authorized access.
get '/oauth_callback' do
  if !session[:request_token]
    redirect to('/')
    return
  end
  request_token = OAuth::RequestToken.new(consumer, session[:request_token], session[:request_secret])
  session.delete(:request_token) # these can't be used any more
  session.delete(:request_secret)
  access_token = request_token.get_access_token(oauth_verifier: params['oauth_verifier'])
  session[:access_token] = access_token.token
  session[:access_secret] = access_token.secret

  # Now that you've got an access token & secret you can use it to make authenticated calls to the Audioboo API.
  # See https://github.com/audioboo/api/blob/master/sections/reference_index.md for
  # all the other calls you can make.
  redirect to('/show_audioboo_account')
end


get '/show_audioboo_account' do
  account_response = access_token.get('http://api.audioboo.fm/account')

  account_info = JSON.parse(account_response.body)
  image_url = account_info['body']['user']['urls']['image']
  <<-HTML
    <h1>Got access token!</h1>
    <p>#{access_token.token} / #{access_token.secret}</p>
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
  local_file = params['audio_file']
  clip_params = {
    'audio_clip[title]' => 'my first boo',
    'audio_clip[uploaded_data]' => UploadIO.new(local_file[:tempfile], local_file[:type], local_file[:filename])
  }

  request = Net::HTTP::Post::Multipart.new('/account/audio_clips', clip_params)
  access_token.sign!(request)
  response = Net::HTTP.start('api.audioboo.fm', 80){|http| http.request(request)}

  response.body
end
