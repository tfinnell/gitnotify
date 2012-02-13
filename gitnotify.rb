#!/usr/bin/env ruby

require 'amqp'
require 'libnotify'
require 'json'
require 'yaml'

$0 = "gitnotify\0"

class Gitnotify
  def initialize(subscription, options, connection)
    channel = AMQP::Channel.new(connection, auto_recovery: true)
    queue = channel.queue(subscription, durable: true)

    queue.subscribe do |md, pl|

      begin
        jpl = JSON.parse(pl)
        icon = options[:icon]
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

      puts "#{head}: #{message}"
      notification({
        summary: head,
        body: message,
        timeout: options[:timeout],
        icon_path: icon})
    end
  end

  def notification(gnotify)
    Libnotify.show(gnotify)
  end
end

SUBSCRIPTIONS = YAML.load_file('config/subscription.yml')

broker = SUBSCRIPTIONS["github"][:cred]

AMQP.start(broker) do |connection|
  product = connection.server_properties["product"] 
  version = connection.server_properties["version"]
  user = connection.settings[:user]
  host = connection.settings[:host]
  port = connection.settings[:port]

  puts " #{user} connected to #{host}:#{port} running #{product} version #{version}..."

  SUBSCRIPTIONS.each do |subscription, options|
    Gitnotify.new(subscription, options[:notification], connection)
  end
end
