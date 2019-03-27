require 'sinatra'
require 'sinatra/base'


class MyApp < Sinatra::Base
  get "/" do
    send_file './public/index.html'
  end
end

