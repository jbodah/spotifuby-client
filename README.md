## spotifuby-client has been merged into the [spotifuby](https://github.com/jbodah/spotifuby) repo

# spotifuby-client
a client library for talking with a [spotifuby](https://github.com/jbodah/spotifuby) server

This library is a Ruby port of [hubot-spotifuby](https://github.com/jbodah/hubot-spotifuby)

## Usage

Clone this repo then in IRB:

```rb
# Add 'lib' to the load path and require the client
$: << 'lib'
require 'spotifuby/client'

# Instantiate a client with your Spotifuby host URI
client = Spotifuby::Client.new('http://localhost:4567')

# Client endpoints are called dynamically using a pattern of
# "#{http_method}_#{endpoint}" such as "post_play"
#
# These calls can also accept a Hash of parameters. Middleware
# takes care of preprocessing the request to make it compliant
# with the Spotifuby server before sending
client.post_play uri: 'spotify:artist:6axequyOfJ1xFxRh2lo48Y'

# You can use the Spotifuby::Bot to integrate with different IO
# such as HipChat or Slack
#
# The bot is responsible for abstracting the client and listening
# to the IO for commands. It calls the client, parses the response,
# and outputs messages
require 'spotifuby/bot'
bot = Spotifuby::Bot.create_default(client, io_adapter)
bot.receive('play me some elton john')
```
