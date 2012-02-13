#!/usr/bin/env ruby

require 'amqp'
require 'libnotify'
require 'json'
require 'yaml'

$0 = "gitnotify\0"

class Gitnotify
  def initialize(subscription, options, connection)
    channel = AMQP::Channel.new(connection)
    queue = channel.queue(subscription, durable: true)

    connection.on_tcp_connection_loss do |connection, settings|
      puts "tcp connection loss"
    end

    connection.on_connection_interruption do |connection|
      puts "Connection interruption?"
    end

    channel.on_error do |ch, channel_close|
      puts channel_close.reply_text
      connection.close { EM.stop }
    end

    queue.subscribe do |md, pl|
      begin
        jpl = JSON.parse(pl)
        icon = options[:icon]
      rescue
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
  puts "Connected to AMQP broker..."

  SUBSCRIPTIONS.each do |subscription, options|
    Gitnotify.new(subscription, options[:notification], connection)
  end
end
