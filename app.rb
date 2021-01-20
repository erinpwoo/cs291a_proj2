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
  regex = /[A-Fa-f0-9]{64}/.match(file)
  if regex == nil
    return 422
  end
  if regex.to_s.length != file.length
    lengths = regex.length.to_s + " " + file.length.to_s
    body lengths
    return 422
  end
  filename = String.new(file)
  filename.insert(2, '/')
  path = filename.insert(5, '/')
  path = path.downcase
  if !bucket.file(path)&.exists?
    body path
    return 404
  end
  downloaded = bucket.file(path)
  content = downloaded.download
  data = content.read
  content.rewind
  header = {"Content-Type" => downloaded.content_type}
  return [200, header, data.to_s]
end

post '/files/' do
  if params == nil
    return 422
  end
  if params['file'] == nil
    body "line 57"
    return 422
  end
  if params['file']['tempfile'] == nil
    body "line 60"
    return 422
  end

  if (!File.file?(params['file']['tempfile'])) 
    body "line 69"
    return 422
  end
  file_size = File.size(params['file']['tempfile'])
  if file_size > 1048576
    body file_size.to_s
    return 422
  end
  if !File.readable?(params['file']['tempfile'])
    body "line 73"
    return 422
  end
  file = File.open params['file']['tempfile']
  digest = Digest::SHA256.hexdigest file.read
  path = digest.insert(2, '/')
  path.insert(5, '/')
  path = path.downcase
  if bucket.file(path)&.exists?
    halt 409
    return
  end
  file.rewind
  file_name = Digest::SHA256.hexdigest file.read
  puts params
  puts file_name
  file.rewind
  bucket.upload_file(file, path, content_type: params['file']['type'])
  json = {'uploaded': file_name}
  puts JSON.generate(json)
  return [201, JSON.generate(json)]
end

delete '/files/:digest' do |file|
  regex = /[A-Fa-f0-9]{64}/.match(file)
  if regex == nil
    return 422
  end
  if regex.to_s.length != file.length
    lengths = regex.length.to_s + " " + file.length.to_s
    body lengths
    return 422
  end
  path = String.new(file.downcase)
  path.insert(2, '/')
  path.insert(5, '/')
  file = bucket.file path
  if file != nil
    file.delete
  end
  return 200
end