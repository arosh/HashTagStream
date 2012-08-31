#最初に#なしのハッシュタグ入れるとscreen_nameとtweetが出てきます
#適当に書き換えればいいと思うよ。

# gem install twitter-stream -s http://gemcutter.org
# -*- encoding: UTF-8 -*-

require 'twitter/json_stream'
require 'twitter'
require 'json'
require 'pp'

CONSUMER_KEY    = ""
CONSUMER_SECRET = ""
OAUTH_TOKEN     = ""
OAUTH_SECRET    = ""

Twitter.configure do |config|
	config.consumer_key       = CONSUMER_KEY
	config.consumer_secret    = CONSUMER_SECRET
	config.oauth_token        = OAUTH_TOKEN
	config.oauth_token_secret = OAUTH_SECRET
end

print 'Please input tags without #: '
TAG = gets.strip

EventMachine::run do
	userstream = {
		:host => "userstream.twitter.com",
		:path => "/2/user.json?replies=all",
		:port => 443,
		:ssl => true,
		:oauth => {
			:consumer_key     => CONSUMER_KEY,
			:consumer_secret  => CONSUMER_SECRET,
			:access_key       => OAUTH_TOKEN,
			:access_secret    => OAUTH_SECRET
		}
	}

	stream = Twitter::JSONStream.connect(userstream)

	stream.each_item do |item|
		event = JSON.parse(item)
		next if event["direct_message"]
		next if event["delete"]
		next if event["friends"]
		if event['entities']['hashtags'].empty? == false &&
			event['entities']['hashtags'][0]['text'] == TAG then
				puts event['user']['screen_name'] + " " + event['text']
		end
	end

	stream.on_error do |message|
		$stderr.puts "error: #{message}"
		$stderr.flush
	end

	stream.on_reconnect do |timeout, retries|
		$stderr.puts "reconnecting in: #{timeout} seconds"
		$stderr.flush
	end

	stream.on_max_reconnects do |timeout, retries|
		$stderr.puts "Failed after #{retries} failed reconnects"
		$stderr.flush
	end

	trap('TERM') {
		stream.stop
		EventMachine.stop if EventMachine.reactor_running?
	}
end
