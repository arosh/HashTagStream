#最初に#なしのハッシュタグ入れるとscreen_nameとtweetが出てきます
#適当に書き換えればいいと思うよ。
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
	config.oauth_token			  = OAUTH_TOKEN
	config.oauth_token_secret = OAUTH_SECRET
end

puts "Please input tags without \'#\'"
TAG = gets.chomp

EventMachine::run do
	userstream = {
		:host => "userstream.twitter.com",
		:path => "/2/user.json?replies=all",
		:port => 443,
		:ssl => true,
		:oauth => {
			:consumer_key		 => CONSUMER_KEY,
			:consumer_secret => CONSUMER_SECRET,
			:access_key			 => OAUTH_TOKEN,
			:access_secret	 => OAUTH_SECRET
		}
	}

	stream = Twitter::JSONStream.connect(userstream)

	stream.each_item do |item|
		event = JSON.parse(item)
		next if event["direct_message"]
		next if event["delete"]
		next if event["friends"]
		if event['entities']['hashtags'] != [] && 
			event['entities']['hashtags'][0]['text'] == TAG then
				puts event['user']['screen_name']+" "+event['text']
		end
	end

	stream.on_error do |message|
		$stdout.print "error: #{message}\n"
		$stdout.flush
	end

	stream.on_reconnect do |timeout, retries|
		$stdout.print "reconnecting in: #{timeout} seconds\n"
		$stdout.flush
	end

	stream.on_max_reconnects do |timeout, retries|
		$stdout.print "Failed after #{retries} failed reconnects\n"
		$stdout.flush
	end

	trap('TERM') {
		stream.stop
		EventMachine.stop if EventMachine.reactor_running?
	}
end
