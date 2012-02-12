#!/usr/bin/env ruby

require 'amqp'
require 'yaml'
require 'libnotify'
require 'json'

$0 = "gitnotify\0"

broker = YAML.load_file("broker.yaml")

AMQP.start(broker) do |connection|
  puts "Connected to AMQP broker..."

  channel = AMQP::Channel.new(connection)
  queue = channel.queue("github", durable: true)

  queue.subscribe do |md, pl|

    jpl = JSON.parse(pl)
    message = jpl["payload"]["message"]
    id = jpl["payload"]["id"]
    repo = jpl["_meta"]["routing_key"].split(".")[3]
    branch = jpl["_meta"]["routing_key"].split(".")[4]
    author = jpl["payload"].has_key?("author") ?
      jpl["payload"]["author"]["username"] : "Something"
    head = "#{author} pushed to #{repo}/#{branch}"

    puts [message, id, head]
    Libnotify.show(body: message,
                   summary: head,
                   timeout: 10,
                   icon_path: "/usr/share/icons/github/github-icon.png")
  end
end
