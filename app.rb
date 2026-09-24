# frozen_string_literal: true

require 'json'
require 'rack/utils'
require 'securerandom'
require 'sinatra'
require 'fileutils'

enable :method_override

MEMOS_FILE = File.join(__dir__, 'data', 'memos.json')

helpers do
  def h(value)
    Rack::Utils.escape_html(value)
  end
end

def load_memos
  JSON.parse(File.read(MEMOS_FILE))
rescue Errno::ENOENT, JSON::ParserError
  {}
end

def save_memos(memos)
  FileUtils.mkdir_p(File.dirname(MEMOS_FILE))
  File.write(MEMOS_FILE, JSON.generate(memos))
end

def find_memo(id)
  load_memos[id]
end

def memo_params
  {
    'title' => params['title'].to_s,
    'description' => params['description'].to_s
  }
end

get '/' do
  redirect '/memos'
end

get '/memos' do
  @memos = load_memos
  erb :index
end

get '/memos/new' do
  @memo = {}
  @errors = []
  erb :new
end

get '/memos/:id/edit' do
  @id = params['id']
  @memo = find_memo(@id)
  if @memo.nil?
    status 404
    return erb :not_found
  end

  @errors = []
  erb :edit
end

get '/memos/:id' do
  @id = params['id']
  @memo = find_memo(@id)
  if @memo.nil?
    status 404
    return erb :not_found
  end

  erb :show
end

not_found do
  erb :not_found
end

post '/memos' do
  @memo = memo_params
  @errors = []

  if @memo['title'].strip.empty?
    @errors << 'タイトルを入力してください'
    status 422
    return erb :new
  end

  memos = load_memos
  id = SecureRandom.uuid
  memos[id] = @memo
  save_memos(memos)

  redirect "/memos/#{id}"
end

patch '/memos/:id' do
  @id = params['id']
  memos = load_memos
  memo = memos[@id]
  if memo.nil?
    status 404
    return erb :not_found
  end

  @memo = memo.merge(memo_params)
  @errors = []

  if @memo['title'].strip.empty?
    @errors << 'タイトルを入力してください'
    status 422
    return erb :edit
  end

  memo.merge!(memo_params)
  save_memos(memos)

  redirect "/memos/#{@id}"
end

delete '/memos/:id' do
  memos = load_memos
  unless memos.key?(params['id'])
    status 404
    return erb :not_found
  end

  memos.delete(params['id'])
  save_memos(memos)

  redirect '/memos'
end
