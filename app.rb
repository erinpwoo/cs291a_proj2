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
  if regex.length != file.length
    return 422
  end
  path = file.insert(2, '/')
  path = path.insert(5, '/')
  if bucket.file(path) == nil
    puts path
    return 404
  end
  downloaded = bucket.file(path)
  content = downloaded.download
  header = {"Content-Type" => downloaded.content_type}
  data = content.read
  return [200, header, data.to_s]
end

post '/files/' do
  if params == nil
    return 422
  end
  if params['file'] == nil
    return 422
  end
  if params['file']['tempfile'] == nil
    return 422
  end
  file_size = File.size(params['file']['tempfile'])
  if file_size == 0 || file_size > 1000000
    return 422
  end
  if !File.readable?(params['file']['tempfile'])
    return 422
  end
  file = File.open params['file']['tempfile']
  digest = Digest::SHA256.hexdigest file.read
  path = digest.insert(2, '/')
  path = path.insert(5, '/')
  if bucket.file(path)&.exists?
    halt 409
    return
  end
  file.rewind
  file_name = Digest::SHA256.hexdigest file.read
  puts file_name
  file.rewind
  bucket.upload_file(file, path)
  json = {'uploaded': file_name}
  puts JSON.generate(json)
  return [201, JSON.generate(json)]
end

delete '/files/:digest' do |file|
  regex = /[A-Fa-f0-9]{64}/.match(file)
  if regex == nil
    return 422
  end
  if regex.length != file.length
    return 422
  end
  path = file.insert(2, '/')
  path = path.insert(5, '/')
  file = bucket.file path
  if file != nil
    file.delete
  end
  return 200
end