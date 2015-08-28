require 'spotifuby/bot/builder'
require 'spotifuby/bot/command'

module Spotifuby
  class Bot
    class << self
      def create(*args)
        bot = new(*args)
        Bot::Builder.new(bot).build
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
end

