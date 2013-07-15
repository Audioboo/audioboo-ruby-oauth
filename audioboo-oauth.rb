#!/usr/bin/env ruby
require 'oauth'
require 'pp'
require 'json'

# Fill in your consumer API key & secret here.  You can obtain an API key from http://audioboo.fm/account/services
KEY = ""
SECRET = ""
raise "You need to fill in your API key" if KEY.empty?

consumer = OAuth::Consumer.new(KEY,SECRET, site: "http://api.audioboo.fm")
# consumer.http.set_debug_output($stderr)

if ARGV.size == 0
  puts "Fetching request token..."
  request_token = consumer.get_request_token(oauth_callback: 'oob')

  puts "Got a request token. #{request_token.inspect}"
  puts "Open #{request_token.authorize_url} to authorize your account"

  begin
    puts "Enter the pin verifier:"
    verifier = gets.chomp
  
    puts "Fetching an access token..."
    access_token = request_token.get_access_token(oauth_verifier: verifier)
  rescue
    p $!
    retry
  end
  puts "Got access token & secret: #{access_token.token} #{access_token.secret}"
else

  access_token = OAuth::AccessToken.new(consumer, ARGV[0], ARGV[1])
end

pp JSON.parse(access_token.get('/account').body)
