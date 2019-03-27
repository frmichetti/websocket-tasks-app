require 'em/pure_ruby'
require 'em-websocket'
require 'rx'
require 'rufus-scheduler'

class MyWebSocket
  def initialize
    EM.run do
      @messages = []
      @scheduler = Rufus::Scheduler.singleton

      @paused = false
      @times = 1
      @amount = 1

      EM::WebSocket.run(host: '0.0.0.0', port: 8080) do |ws|

        source = Rx::Observable.from_array(@messages)
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

          if msg.eql? 'reset'
            @times = 1
            @amount = 1
            ws.send "Pong: #{'ok - resetting count'}"
          elsif msg.eql? 'pause'
            @paused = !@paused
            puts 'Paused ? ', @paused
            ws.send @paused ? "Pong: #{'shhhhhhhhhh'}" : "Pong: #{'counting ...'}"
          else
            @messages << msg
            ws.send "Pong: #{msg}"
          end
        end

        @ws = ws
      end

      @scheduler.every '2s' do
        # @ws.send "scheduler message #{Time.now}" if @ws
        #

        if @ws
          unless @paused
            if @amount == 1
              @ws.send("#{@amount} elefante incomoda muita gente!")
            else
              if @amount % 2 == 0
                disturb = ""
                i = 0
                for i in i..@times do
                  disturb += "incomodam "
                end
                @ws.send("#{@amount} elefantes #{disturb}muito mais!")
              else
                @ws.send("#{@amount} elefantes incomodam muita gente!")
              end
            end
            @amount+=1
            @times+=1
          end
        end
      end

      puts 'Websocket Server Started'
    end
  end
end

run MyWebSocket.new