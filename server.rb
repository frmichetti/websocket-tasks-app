require 'em/pure_ruby'
require 'em-websocket'
require 'rx'
require 'rufus-scheduler'

EM.run do
  messages = []
  @scheduler = Rufus::Scheduler.singleton

  EM::WebSocket.run(host: '0.0.0.0', port: 8080) do |ws|

    source = Rx::Observable.from_array(messages)
    subscription = source.subscribe(
        lambda {|x|
          puts 'Next: ' + x.to_s
        },
        lambda {|err|
          puts 'Error: ' + err.to_s
        },
        lambda {
          puts 'Completed'
        })


    ws.onopen do |handshake|
      puts 'WebSocket connection open'

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send "Hello Client, you connected to #{handshake.path}"

      @ws = ws
    end

    ws.onclose do
      puts 'Connection closed'
      subscription.unsubscribe
    end

    ws.onmessage do |msg|
      puts "Received message: #{msg}"
      messages << msg
      ws.send "Pong: #{msg}"
    end

    @ws = ws
  end

  @scheduler.every '3s' do
    @ws.send "scheduler message #{Time.now}" if @ws
  end



  puts 'Server Started'
end
