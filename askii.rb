require 'net/http'
require 'sequel'
require 'twitter'
require 'uri'
require 'yaml'
require 'RMagick'

class Askii

  class Art

    class <<self
      TEMP_FILE_CHARS = [('a'..'z'), ('A'..'Z')].map {|i| i.to_a}.flatten

      def generate_file_name(length: 8)
        (0...length).map {TEMP_FILE_CHARS[rand(TEMP_FILE_CHARS.length)]}.join
      end

      def average_luminosity(image)
        r = g = b = 0.0
        n = image.rows * image.columns
        denom = n * Magick::QuantumRange

        image.each_pixel do |px|
          r += px.red.to_f / denom
          g += px.green.to_f / denom
          b += px.blue.to_f / denom
        end

        0.2126 * r + 0.7152 * g + 0.0722 * b

      end
    end

    attr_reader :url, :directory, :file, :luminosity

    def initialize(url, directory: '.')
      url = URI.parse url if url.is_a? String
      @url = url
      @directory = directory
    end

    def process!
      save_jpeg! or return false
      render_ascii!
      render_png!
      true
    end

    protected

    def save_jpeg!(follow_redirect: 1)
      resp = Net::HTTP.get_response @url

      follow_redirect.times do
        break if resp.code != "302"
        resp = Net::HTTP.get_response resp['location']
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

      @file = File.join @directory, self.class.generate_file_name
      @luminosity = self.class.average_luminosity image

      image.write "#{@file}.jpg"
    end

    def render_ascii!
      flags = %w(--html --color)
      flags << '--invert' if @luminosity > 0.72

      html = `jp2a #{flags} #{@file}.jpg`
      File.open "#{@file}.html", "w" do |f|
        f.write html
      end
    end

    def render_png!
      `phantomjs capture.js #{@file}.html #{@file}.png`
    end
    
  end

  class <<self

    def get_media_urls(tweet)
      images = tweet.media.select {|m| m.is_a? Twitter::Media::Photo}
      images.map &:media_url
    end

    def get_urls(tweet)
      tweet.urls.map {|u| URI.parse u.expanded_url}
    end

    def process_tweet_images(tweet, directory: '.')
      urls = self.get_media_urls(tweet) + self.get_urls(tweet)
      urls.map do |url|
        art = Art.new url, directory: directory
        art.process! ? art : nil
      end.compact
    end

    def init_db(db)
      db.create_table :access do
        integer :since_id
      end
    end

  end

  attr_reader :client, :db, :work_directory 

  def initialize(config_file: 'config.yaml')
      params = YAML.load_file config_file

      @client = Twitter::REST::Client.new do |config|
        params['twitter'].each do |k, v|
          config.send "#{k}=", v
        end
      end

      @work_directory = params['filesystem']['work_directory']
      @db = Sequel.sqlite params['filesystem']['db_file']
  end

end
