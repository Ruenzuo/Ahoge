require 'twitter'
require 'yaml'
require 'sqlite3'

module Ahoge
  class Main
    attr_reader :client
    
    def self.amuse
      main = Main.new
      main.setup_database
      main.setup_client
      tweet_text, media_url = main.get_last_follower_last_photo
      main.store_media_url(media_url)
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

    def setup_database
      @db = SQLite3::Database.new "ahoge.db"
      @db.execute(<<-SQL
        SELECT name
        FROM sqlite_master
        WHERE type='table'
        AND name='media_urls';
      SQL
      ) do |row|
        return
      end
      @db.execute <<-SQL
        CREATE TABLE media_urls (
          media_url varchar(140)
        );
      SQL
      puts 'Table media_urls created'
    end

    def get_last_follower_last_photo
      followers = @client.followers([:skip_status => true, :include_user_entities => false])
      followers.each { |follower|
        information = viable_information?(follower)
        return information unless information.empty?
      }
    end

    def viable_information?(user)
      tweets = @client.user_timeline(user, [:exclude_replies => true, :include_rts => false])
      tweets.each { |tweet|
        next unless tweet.media?
        tweet.media.each { |media|
            return [tweet.text, media.media_url] if media.is_a?(Twitter::Media::Photo) and valid_media?(media)
        }
      }
      return []
    end

    def valid_media?(media)
      @db.execute("SELECT media_url FROM media_urls WHERE media_url=\'#{media.media_url}\'") do |row|
        return false
      end
      return true
    end

    def store_media_url(media_url)
      @db.execute('INSERT INTO media_urls (media_url) VALUES (?)', [media_url.to_s])
    end
  end
end
