require 'twitter'
require 'yaml'

module Ahoge
  class Main
    attr_reader :client
    
    def self.amuse
      main = Main.new
      main.setup_client
      information = main.get_last_follower_last_photo
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

    def get_last_follower_last_photo
      followers = @client.followers([:skip_status => true, :include_user_entities => false])
      followers.each { |follower|
        information = viable_information?(follower)
        return information unless information.empty?
      }
    end

    def viable_information?(user)
      tweets = @client.user_timeline(user)
      tweets.each { |tweet|
        next unless tweet.media?
        tweet.media.each { |media|
            return [tweet.text, media.media_url] if media.is_a?(Twitter::Media::Photo)
        }
      }
      return []
    end
  end
end
