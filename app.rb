require 'sinatra'
require 'pp' # used for printing
require'google/cloud/storage'
require 'digest'

# setting up gcs bucket
storage = Google::Cloud::Storage.new(project_id: 'cs291a')
bucket = storage.bucket 'cs291project2', skip_lookup: true

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
  if params['file'] == nil
    halt 422
    return
  end
  file = File.open params['file']['tempfile']
  if file.size > 1000000
    halt 422
    return
  end
  digest = Digest::SHA256.hexdigest file.read
  path = digest.insert(2, '/')
  path = path.insert(5, '/')
  if bucket.file path != nil
    halt 409
    return
  end
  name = Digest::SHA256.hexdigest file.read
  bucket.upload_file(file, path)
  json = {'uploaded': name}
  status 201
  body json
  "POST\n"
end

delete '/files/:digest' do |file|
  PP.pp request # printing request
  "DELETE \n"
end
