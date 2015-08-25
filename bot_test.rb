require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'spy'
require 'mocha/mini_test'
require 'ostruct'

$LOAD_PATH << '.'
require 'bot'

class MockNet
  class << self
    def get(*args); end
    def pots(*args); end
  end
end

class MockIO
  class << self
    def <<(*args); end
  end
end

class BotTest < Minitest::Spec
  describe 'spotifuby info' do
    before do
      @net = MockNet
      @io = MockIO
      @spotifuby = Spotifuby::Client.new('http://localhost:4567')

      @bot = Spotifuby::Bot.new(@spotifuby, @net, @io)
    end

    after do
      Spy.restore(:all)
    end

    it 'makes a request to /' do
      spy = Spy.on(@net, :get)

      @bot.receive('spotifuby info')

      assert_equal 1, spy.call_count
      assert_equal 'http://localhost:4567', spy.call_history[0].args[0]
    end

    it 'outputs host url' do
      spy = Spy.on(@io, :<<)

      @bot.receive('spotifuby info')

      assert_equal 1, spy.call_count
      assert spy.call_history[0].args[0].include?(@spotifuby.host)
    end

    describe 'when host is down' do
      it 'outputs that the host is down' do
        @net.stubs(:get).raises(StandardError)
        spy = Spy.on(@io, :<<)

        @bot.receive('spotifuby info')

        assert_equal 1, spy.call_count
        assert spy.call_history[0].args[0].include?('Status - down')
      end
    end

    describe 'when the host is up' do
      it 'outputs that the host is up' do
        @net.stubs(:get).returns(OpenStruct.new(status: 200))
        spy = Spy.on(@io, :<<)

        @bot.receive('spotifuby info')

        assert_equal 1, spy.call_count
        assert spy.call_history[0].args[0].include?('Status - up')
      end
    end
  end
end
