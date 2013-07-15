# Fill in your consumer API key & secret here.  You can obtain an API key from http://audioboo.fm/account/services
KEY = ""
SECRET = ""
if KEY.empty?
  puts "Enter your API key in #{__FILE__} before continuing"
  exit 1
end
