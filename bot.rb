require 'faraday'

class Bot
  class Command
    def initialize(regex, &block)
      @regex = regex
      @block = block
    end

    def call(*args)
      @block.call(*args)
    end

    def match(other)
      @regex.match(other)
    end
  end

  attr_reader :spotifuby, :net, :io

  def initialize(spotifuby, net, io)
    @io = io
    @commands = []
    @spotifuby = spotifuby
    @net = net
    if block_given?
      instance_eval &Proc.new
    end
  end

  def on(regex, opts = {}, &block)
    @commands.push(Command.new(regex, &block))
  end

  def receive(msg)
    @commands.each do |command|
      md = command.match(msg)
      command.call(*md[1..-1]) if md
    end
  end
end

# TODO is this needed?
class FaradayNetAdapter
  def initialize
    @client = Faraday.new
  end

  def get(url)
    @client.get(url)
  end

  def post(url, params)
    @client.post(url, params)
  end
end

module Spotifuby
  class Client
    attr_reader :host

    def initialize(host, net)
      @host = host
      @net = net
    end

    def url_for(part)
      File.join(@host, part)
    end

    def get_spotifuby_info
      @net.get @host
    end

    def method_missing(sym, *args, &block)
      super unless /^(?<method_name>get|post)_(?<api_method>\w+)/ =~ sym.to_s
      @net.public_send(method_name, url_for(api_method), *args)
    end

    def respond_to_missing?(sym, incl_private = false)
      true if /^(?<method_name>get|post)_(?<api_method>\w+)/ =~ sym.to_s
      super
    end
  end
end

class Spotifuby::Bot < Bot
  def initialize(*args)
    super(*args) do
      on /spotifuby info/, help: 'spotifuby info - Displays info about Spotifuby server' do
        is_up = begin
                  r = spotifuby.get_spotifuby_info
                  r.status == 200
                rescue
                  false
                end
        io << <<-MSG
Host - #{spotifuby.host}
Status - #{is_up ? 'up' : 'down'}
        MSG
      end

      on /(?<!un)mute/, help: 'mute - Set volume to 0' do
        spotifuby.post_set_volume volume: 0
        #io << 'As you wish'
      end

      on /unmute/, help: 'unmute - Set volume to max' do
        spotifuby.post_set_volume volume: 100
        #io << 'As you wish'
      end

      on /set volume (\d+)/, help: 'set volume <0-100> - Set volume' do |volume|
        spotifuby.post_set_volume volume: volume
        #io << 'As you wish'
      end

      # TODO - add fresh time
      on /skip track/, help: 'skip track - Play next track' do
        spotifuby.post_next
      end

      on /(pause|stop) music/, help: 'pause music (alias: stop music) - Pause current track' do
        spotifuby.post_pause
      end

      on /(play|resume) music/, help: 'play music (alias: resume music) - Resume playing current track' do
        spotifuby.post_play
      end

      [:play, :enqueue].each do |action|
        on /#{action} uri (\S+)/, help: "#{action} uri <URI> - #{action.to_s.capitalize} the given Spotify URI" do |uri|
          spotifuby.public_send("post_#{action}", uri: uri)
        end
      end

      on /play default playlist/, help: 'play default playlist - Plays the default playlist' do
        spotifuby.post_play_default_uri
      end
    end
  end
end

