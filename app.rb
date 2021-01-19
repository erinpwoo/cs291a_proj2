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
end

get '/files/' do
  PP.pp request # printing request
  files = bucket.files
  hashes = []
  files.all do |file|
    downloaded = file.download
    downloaded.rewind
    digest = Digest::SHA256.hexdigest downloaded.read
    hashes.append(digest)
  end
  hashes.sort
  return [200, JSON.generate(hashes)]
end

get '/files/:digest' do |file|
  if /[A-Fa-f0-9]{64}/.match(file) == nil 
    return 422
  end
  path = file.insert(2, '/')
  path = path.insert(5, '/')
  if !bucket.file(path)&.exists?
    return 404
  end
  downloaded = bucket.file(path)
  content = downloaded.download
  header = {"Content-Type" => downloaded.content_type}
  data = content.read
  return [200, header, data.to_s]
end

post '/files/' do
  if params['file'] == nil || params['file']['tempfile'] == nil
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
  if bucket.file(path)&.exists?
    halt 409
    return
  end
  name = Digest::SHA256.hexdigest file.read
  bucket.upload_file(file, path)
  json = {'uploaded': name}
  return [201, JSON.generate(json)]
end

delete '/files/:digest' do |file|
  PP.pp request # printing request
end
