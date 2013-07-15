audioboo-ruby-oauth
===================

Some examples using the Ruby OAuth gem to talk to the [audioboo.fm](http://audioboo.fm) API.

Installation
============

```
git clone https://github.com/Audioboo/audioboo-ruby-oauth.git
cd audioboo-ruby-oauth
bundle install
```

Edit consumer_key.rb to include your API consumer key & secret.  You can obtain these from your [Audioboo services page](http://audioboo.fm/account/services).

Usage
=====

`audioboo-oauth-cli.rb` is a command-line tool that uses 'out-of-band' verification, typically used in serverless apps like a desktop client.

```
bundle exec ruby audioboo-oauth-cli.rb
```


`audioboo-oauth-webapp.rb` is a small Sinatra app that performs OAuth in typical fashion for a web app.

```
bundle exec ruby audioboo-oauth-webapp.rb
```

You can then view the web app at [http://localhost:4567](http://localhost:4567)
