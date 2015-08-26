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
    def post(*args); end
  end
end

class MockIO
  class << self
    def <<(*args); end
  end
end

class BotTest < Minitest::Spec
  before do
    @net = MockNet
    @io = MockIO
    @spotifuby = Spotifuby::Client.new('http://localhost:4567')

    @bot = Spotifuby::Bot.new(@spotifuby, @net, @io)
  end

  after do
    Spy.restore(:all)
  end

  describe 'spotifuby info' do
    it 'makes a get to /' do
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

  describe 'mute' do
    it 'makes a post to /set_volume with volume of 0' do
      spy = Spy.on(@net, :post)

      @bot.receive('mute')

      assert_equal 1, spy.call_count
      assert_equal 'http://localhost:4567/set_volume', spy.call_history[0].args[0]
      assert_equal 0, spy.call_history[0].args[1][:volume]
    end
  end

  describe 'unmute' do
    it 'makes a post to /set_volume with volume of 0' do
      spy = Spy.on(@net, :post)

      @bot.receive('unmute')

      assert_equal 1, spy.call_count
      assert_equal 'http://localhost:4567/set_volume', spy.call_history[0].args[0]
      assert_equal 100, spy.call_history[0].args[1][:volume]
    end
  end
end
