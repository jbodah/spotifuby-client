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

#require 'faraday'


## TODO is this needed?
#class FaradayNetAdapter
  #def initialize
    #@client = Faraday.new
  #end

  #def get(url)
    #@client.get(url)
  #end

  #def post(url, params)
    #@client.post(url, params)
  #end
#end
