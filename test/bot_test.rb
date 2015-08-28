require 'test_helper'
require 'spotifuby/client'
require 'spotifuby/bot'

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
    @spotifuby = Spotifuby::Client.new('http://localhost:4567', @net)

    @bot = Spotifuby::Bot.create(@spotifuby, @io)

    @net_spies = [:get, :post].each_with_object({}) do |meth, memo|
      memo[meth] = Spy.on(@net, meth)
    end

    @io_spy = Spy.on(@io, :<<)
  end

  after do
    Spy.restore(:all)
  end

  describe 'spotifuby info' do
    it 'gets to /' do
      @bot.receive 'spotifuby info'

      assert_requested get: ''
    end

    it 'outputs host url' do
      @bot.receive 'spotifuby info'

      assert_equal 1, @io_spy.call_count
      assert @io_spy.call_history[0].args[0].include?(@spotifuby.host)
    end

    describe 'when host is down' do
      it 'outputs that the host is down' do
        @net.stubs(:get).raises(StandardError)

        @bot.receive 'spotifuby info'

        assert_equal 1, @io_spy.call_count
        assert @io_spy.call_history[0].args[0].include?('Status - down')
      end
    end

    describe 'when the host is up' do
      it 'outputs that the host is up' do
        @net.stubs(:get).returns(OpenStruct.new(status: 200))

        @bot.receive 'spotifuby info'

        assert_equal 1, @io_spy.call_count
        assert @io_spy.call_history[0].args[0].include?('Status - up')
      end
    end
  end

  it 'posts to /set_volume with volume of 0 on mute' do
    @bot.receive 'mute'
    assert_requested post: 'set_volume', volume: 0
  end

  it 'posts to /set_volume with volume of 0 on unmute' do
    @bot.receive 'unmute'
    assert_requested post: 'set_volume', volume: 100
  end

  describe 'set volume' do
    it 'posts to /set_volume with volume of 30 on set volume 30' do
      @bot.receive 'set volume 30'
      assert_requested post: 'set_volume', volume: 30
    end

    it 'posts to /set_volume with volume of 60 on set volume 60' do
      @bot.receive 'set volume 60'
      assert_requested post: 'set_volume', volume: 60
    end
  end

  it 'posts to /next on skip track' do
    @bot.receive 'skip track'
    assert_requested post: 'next'
  end

  it 'posts to /pause on pause music' do
    @bot.receive 'pause music'
    assert_requested post: 'pause'
  end

  it 'posts to /pause on stop music' do
    @bot.receive 'stop music'
    assert_requested post: 'pause'
  end

  it 'posts to /play on play music' do
    @bot.receive 'play music'
    assert_requested post: 'play'
  end

  it 'posts to /play on resume music' do
    @bot.receive 'resume music'
    assert_requested post: 'play'
  end

  it 'posts to /play with the uri on play uri 12345' do
    @bot.receive 'play uri 12345'
    assert_requested post: 'play', uri: '12345'
  end

  it 'posts to /enqueue with the uri on enqueue uri 12345' do
    @bot.receive 'enqueue uri 12345'
    assert_requested post: 'enqueue', uri: '12345'
  end

  it 'posts to /play_default_uri on play default playlist' do
    @bot.receive 'play default playlist'
    assert_requested post: 'play_default_uri'
  end

  #describe 'play me some' do
    #it 'does things' do
      #fail
    #end
  #end

  #describe 'enqueue me some' do
    #it 'does things' do
      #fail
    #end
  #end

  #describe 'enqueue track' do
    #it 'does things' do
      #fail
    #end
  #end

  #describe 'whats playing' do
    #it 'does things' do
      #fail
    #end
  #end

  #describe 'who added this' do
    #it 'does things' do
      #fail
    #end
  #end

  private

  def assert_requested(args = {})
    uri = nil
    spy = nil
    [:post, :get].find do |sym|
      next unless uri = args.delete(sym)
      spy = @net_spies[sym]
    end

    expected_uri = 'http://localhost:4567'
    expected_uri = [expected_uri, uri].join('/') if uri.size > 0

    assert_equal expected_uri, spy.call_history[0].args[0],
      "expected call to #{expected_uri}"

    args.each do |key, val|
      assert_equal val.to_s, spy.call_history[0].args[1][key].to_s,
        "expected call to have argument #{key}: #{val}"
    end
  end
end
