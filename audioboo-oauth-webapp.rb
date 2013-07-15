#!/usr/bin/env ruby
require 'bundler/setup'
require 'oauth'
require 'sinatra'
require 'json'
require_relative './consumer_key'

# This minimal web app uses OAuth to fetch a access token key & secret from audioboo.fm

def consumer
  @consumer ||= OAuth::Consumer.new(KEY,SECRET, site: "http://api.audioboo.fm")
  # @consumer.http.set_debug_output($stderr)
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

  # Now that you've got an access token & secret you can use it to make authenticated calls to the Audioboo API.
  # See https://github.com/audioboo/api/blob/master/sections/reference_index.md for
  # all the other calls you can make.
  account_response = access_token.get('http://api.audioboo.fm/account')

  account_info = JSON.parse(account_response.body)
  image_url = account_info['body']['user']['urls']['image']
  <<-HTML
    <h1>Got access token!</h1>
    <p>#{access_token.token} / #{access_token.secret}</p>
    <h2>Your audioboo account:</h2>
    <pre>#{CGI.escape_html JSON.pretty_generate(account_info) }</pre>
    <img src="#{image_url}"/>
  HTML
end

