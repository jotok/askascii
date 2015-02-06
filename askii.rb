require 'net/http'
require 'twitter'
require 'uri'
require 'yaml'
require 'RMagick'

module Askii

  class <<self

    EXT = %w{jpg jpeg png gif}

    TEMP_FILE_CHARS = [('a'..'z'), ('A'..'Z')].map {|i| i.to_a}.flatten

    def connect(params)

      @client = Twitter::REST::Client.new do |config|
        params['twitter'].each do |k, v|
          config.send "#{k}=", v
        end
      end
    end

    def get_media_urls(tweet)
      images = tweet.media.select {|m| m.is_a? Twitter::Media::Photo}
      images.map &:media_url
    end

    def get_urls(tweet)
      tweet.urls.map {|u| URI.parse u.expanded_url}
    end

    def generate_file_name(length: 8)
      (0...length).map {TEMP_FILE_CHARS[rand(TEMP_FILE_CHARS.length)]}.join
    end

    def average_luminosity(im)
    end

    def save_image(url, params)
      resp = Net::HTTP.get_response url

      # try 1 redirect
      if resp.code == "302"
        resp = Net::HTTP.get_response URI.parse(resp['location'])
      end

      begin
        # Image.from_blob returns a list of Image objects Adding them to an ImageList and
        # flattening ensures that png transparency is properly handled

        ilist = Magick::ImageList.new
        Magick::Image.from_blob(resp.body).each {|im| ilist << im}
        image = ilist.flatten_images
      rescue Magick::ImageMagickError
        puts 'An error occurred while trying to encode the image.'
        return nil
      end

      output_dir = params['filesystem']['output_directory']
      file = File.join output_dir, self.generate_file_name
      image.write "#{file}.jpg"

      file
    end

    def make_ascii(file, params)
      html = `#{params['filesystem']['jp2a_program']} --html --color #{file}.jpg`
      File.open "#{file}.html", "w" do |f|
        f.write html
      end
    end

    def render_html(file)
      `phantomjs capture.js #{file}.html #{file}.png`
    end

    def process_tweet_images(tweet, params)
      urls = self.get_media_urls(tweet) + self.get_urls(tweet)
      urls.map do |url|
        self.save_image url, params
      end.compact.inject([]) do |acc, file|
        self.make_ascii f, params
        self.render_html f
        acc << f
      end
    end

    def process_tweets(tweets, params)

    end

  end

end

# params = YAML::load_file(config_file)
