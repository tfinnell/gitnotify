#!/usr/bin/env ruby

require 'amqp'
require 'libnotify'
require 'json'
require 'yaml'
require 'pry'

$0 = "gitnotify\0"

class Gitnotify
  def initialize(subscription, options, connection)
    channel = AMQP::Channel.new(connection, auto_recovery: true)
    queue = channel.queue(subscription, durable: true)

    EM::PeriodicTimer.new 30.0 do
      puts "#{Time.now} - still alive... "
    end

    queue.subscribe do |md, pl|

      connection.on_connection_interruption do
        puts "connection interruption"
      end

      connection.on_tcp_connection_failure do
        puts "connection tcp connection failure"
      end

      connection.on_tcp_connection_loss do
        puts "tcp connection loss"
      end

      channel.on_error do
        puts "channel error"
      end

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

  puts " #{user} on #{connection.broker_endpoint} running #{product} version #{version}..."

  SUBSCRIPTIONS.each do |subscription, options|
    Gitnotify.new(subscription, options[:notification], connection)
  end
end
