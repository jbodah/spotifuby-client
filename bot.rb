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

    def ==(other)
      !!other[@regex]
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
      command.call if command == msg
    end
  end
end

module Spotifuby
  class Client
    attr_reader :host

    def initialize(host)
      @host = host
    end

    def url_for(part)
      File.join(@host, part)
    end
  end
end

class Spotifuby::Bot < Bot
  def initialize(*args)
    super(*args) do
      on /spotifuby info/, help: 'spotifuby info - Displays info about Spotifuby server' do
        is_up = begin
                  r = net.get spotifuby.host
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
        net.post spotifuby.url_for('set_volume'), { volume: 0 }
        io << 'As you wish'
      end

      on /unmute/, help: 'unmute - Set volume to max' do
        net.post spotifuby.url_for('set_volume'), { volume: 100 }
        io << 'As you wish'
      end

      #on /set volume (\d+)/, help: 'set volume <0-100> - Set volume' do
        #net.post spotifuby.host('set_volume'), { volume: 100 }
      #end
    end
  end
end

