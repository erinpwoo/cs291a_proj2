require 'sinatra'
require 'pp' # used for printing
require'google/cloud/storage'

# setting up gcs bucket
storage = Google:Cloud::Storage.new(project_id: cs291a)
bucket = storage.bucket 'cs291project2', skip_lookup=true

get '/' do
  PP.pp request # printing request
  redirect to('/files/')
  status 302
  "location: " + request.path_info + "/files/"
  "GET /\n"
end

get '/files/' do
  PP.pp request # printing request
  "GET /files/\n"
end

get '/files/:digest' do |file|
  PP.pp request # printing request
  "GET /files/{DIGEST}\n"
end

post '/files/' do
  PP.pp request # printing request
  "POST\n"
end

delete '/files/:digest' do |file|
  PP.pp request # printing request
  "DELETE \n"
end
