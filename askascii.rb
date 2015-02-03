require 'twitter'
require 'yaml'

params = YAML::load_file('config.yaml')

client = Twitter::REST::Client.new do |config|
  params['twitter'].each do |k, v|
    config.send "#{k}=", v
  end
end

# client.update "Thanks, twitter gem: https://github.com/sferik/twitter"

puts client.user_timeline("askascii")
