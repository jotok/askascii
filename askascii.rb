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

    def save_image(url, params)
      resp = Net::HTTP.get_response url

      # test for redirect?

      begin
        ary = Magick::Image.from_blob resp.body
      rescue Magick::ImageMagickError
        puts 'An error occurred while trying to encode the image.'
        return nil
      end

      files = ary.map {self.generate_file_name}

      ary.zip(files).each do |image, file|
        image.write File.join(params['filesystem']['output_directory'], file)
      end

      files
    end

  end

end

# params = YAML::load_file(config_file)
