require 'sinatra'
require 'pp' # used for printing

get '/' do
  PP.pp request # printing request
  "GET/\n"
end

get '/files/' do
  PP.pp request # printing request
  "GET/files/\n"
end

get '/files/:digest' do |file|
  PP.pp request # printing request
  "GET/files/{DIGEST}\n"
end

post '/files' do
  PP.pp request # printing request
  "POST\n"
end
