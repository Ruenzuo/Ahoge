require 'twitter'
require 'yaml'
require 'mini_magick'

module Ahoge
  class Main
    attr_reader :client
    
    def self.amuse
      main = Main.new
      main.setup_client
      tweet, tweet_text, media_url = main.get_last_tweet_in_peru
      # tweet_text, media_url = main.get_last_follower_last_photo
      if tweet_text.nil? or media_url.nil? or tweet.nil?
        abort('No suitable content found')
      end
      tweet_summarized = main.summarize(tweet_text)
      main.magic(tweet_summarized, media_url)
      main.tweet(tweet, tweet_summarized, File.new("tweet.png"))
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

    def tweet(tweet, tweet_text, file)
      @client.update_with_media("#{tweet_text}", file, :in_reply_to_status => tweet, :result_type => "recent")
    end

    def get_last_tweet_in_peru
      @client.search("", :geocode => '-12.05,-77.05,10000km').each { |tweet|
        information = information?(tweet)
        return information unless information.empty?
      }
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
        information = information?(tweet)
        return information unless information.empty?
      }
      return []
    end

    def information?(tweet)
      return [] unless tweet.media?
      tweet.media.each { |media|
        return [tweet, tweet.text, media.media_url.to_s] if media.is_a?(Twitter::Media::Photo)
      }
      return []
    end

    def summarize(tweet_text)
      tokens = tweet_text.split
      tokens.reject! { |token| token.start_with?('http') or token.start_with?('@')}
      return tweet_text if tokens.count < 6
      limit = tokens.count - 2
      random = rand(3..limit)
      return "#{tokens[random - 1]} #{tokens[random]} #{tokens[random + 1]}"
    end

    def magic(tweet_text, media_url)
      image = MiniMagick::Image.open(media_url)
      frame = MiniMagick::Image.open('frame.png')
      frame.resize("#{image.width}x#{image.height}")
      anchor = image.width - frame.width
      result = image.composite(frame) do |c|
        c.compose 'Over'
        c.geometry "+#{anchor}+0"
      end
      text_anchor = image.height / 4
      result.combine_options do |c|
        c.font 'helvetica'
        c.gravity 'Center'
        c.stroke 'black'
        c.strokewidth 4
        c.pointsize '50'
        c.draw "text 0,#{text_anchor} '#{tweet_text}'"
      end
      result.combine_options do |c|
        c.font 'helvetica'
        c.gravity 'Center'
        c.fill 'white'
        c.pointsize '50'
        c.draw "text 0,#{text_anchor} '#{tweet_text}'"
      end
      result.write 'tweet.png'
    end
  end
end
