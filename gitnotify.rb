#!/usr/bin/env ruby

require 'amqp'
require 'json'
require 'yaml'
require 'libnotify'

$0 = "gitnotify\0"

SUBSCRIPTIONS = YAML.load_file('config/subscription.yml')

broker = SUBSCRIPTIONS["github"][:cred]

AMQP.start(broker) do |connection|
  product = connection.server_properties["product"] 
  version = connection.server_properties["version"]
  user = connection.settings[:user]
  options = SUBSCRIPTIONS["github"]

  puts " #{user} on #{connection.broker_endpoint} running #{product} version #{version}..."

  channel = AMQP::Channel.new(connection, auto_recovery: true)
  queue = channel.queue("github", durable: true)

  Signal.trap('INT') do
    AMQP.stop { EM.stop { exit } }
    puts ""
  end

  queue.subscribe do |md, pl|

    begin
      jpl = JSON.parse(pl)
      icon = options[:notification][:icon]
    rescue JSON::ParserError
      jpl = JSON.parse '{"payload":{"message":"someones sending bad JSON :(","id":"error","author":{"username": "system"}},"_meta":{ "routing_key":"system.error.fed.bad.json"}}'
      icon =  Dir["/home/tim/git/trollicons/Icons/#{["Sad","Rage"].sample}/*"].sample
    end
    
    message = jpl["payload"]["message"]
    id = jpl["payload"]["id"]
    repo = jpl["_meta"]["routing_key"].split(".")[3]
    branch = jpl["_meta"]["routing_key"].split(".")[4]
    author = jpl["payload"].has_key?("author") ?
      jpl["payload"]["author"]["username"] : "Something"
    head = "#{author} pushed to #{repo}/#{branch}"

    notification = Libnotify.new do |n|
      n.summary   = head
      n.body      = message
      n.timeout   = 6
      n.icon_path = icon
    end

    EM.next_tick do
      puts "#{head}:"
      notification.show!
      puts "  #{message}"
    end
  end
end
