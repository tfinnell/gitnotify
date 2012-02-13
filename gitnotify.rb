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

    queue.subscribe do |md, pl|

      jpl = JSON.parse(pl)
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
        icon_path: options[:icon]})
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
