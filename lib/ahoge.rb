require 'twitter'
require 'yaml'

module Ahoge
  class Main
    attr_reader :client
    
    def self.amuse
      main = Main.new
      main.setup_client
      main.client.update('Whoops!')
    end

    def setup_client
      auth = YAML.load_file(File.join(File.dirname(__FILE__), '../auth.yaml'))
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = auth['consumer_key']
        config.consumer_secret  = auth['consumer_secret']
        config.access_token = auth['access_token']
        config.access_token_secret = auth['access_token_secret']
      end
    end
  end
end
