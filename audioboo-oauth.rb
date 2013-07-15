#!/usr/bin/env ruby
require 'oauth'
require 'pp'
require 'json'

# This command-line tool uses OAuth to fetch a access token key & secret from audioboo.fm
# Verification is done 'out-of-band' - the user copies a pin from the authorization page
# on audioboo, and pastes it back into the command line tool.
# Once the access token is obtained, it can be used to authenticate as that user for any
# future API calls.

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


puts "Fetching your account details from http://api.audioboo.fm/account"
pp JSON.parse(access_token.get('/account').body)

# See https://github.com/audioboo/api/blob/master/sections/reference_index.md for
# all the other calls you can make.
