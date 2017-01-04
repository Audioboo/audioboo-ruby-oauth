#!/usr/bin/env ruby
require 'bundler/setup'
require 'oauth2'
require 'pp'
require 'json'

require_relative './consumer_key'

client = OAuth2::Client.new(
  KEY,
  SECRET,
  site: "https://api.audioboom.com",
  authorize_url: "/authorize",
  token_url: "/token"
)

puts "Open #{client.auth_code.authorize_url} to authorize your account"

begin
  puts "Enter the pin:"
  pin = gets.chomp

  puts "Fetching an access token..."
  token = client.auth_code.get_token(pin)
rescue
  p $!
  retry
end
puts "Got access token: #{token.token}"

puts "Fetching your account details from http://api.audioboom.com/account"
pp JSON.parse(token.get('/account').body)

# See https://github.com/audioboo/api/blob/master/sections/reference_index.md for
# all the other calls you can make.
