# frozen_string_literal: true

require 'pg'
require 'rack/utils'
require 'securerandom'
require 'sinatra'

enable :method_override

DB_NAME = 'memo_app'
UUID_PATTERN = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

configure do
  conn = PG.connect(dbname: DB_NAME)
  conn.exec(<<~SQL)
    CREATE TABLE IF NOT EXISTS memos (
      id uuid PRIMARY KEY,
      title text NOT NULL,
      description text NOT NULL DEFAULT '',
      created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  SQL
ensure
  conn&.close
end

helpers do
  def h(value)
    Rack::Utils.escape_html(value)
  end

  def db
    @db ||= PG.connect(dbname: DB_NAME)
  end
end

after do
  @db&.close
end

def uuid?(id)
  id.match?(UUID_PATTERN)
end

def load_memos
  db.exec('SELECT id, title FROM memos ORDER BY created_at').to_a
end

def find_memo(id)
  return nil unless uuid?(id)

  db.exec_params('SELECT title, description FROM memos WHERE id = $1', [id]).first
end

def create_memo(id, memo)
  db.exec_params(
    'INSERT INTO memos (id, title, description) VALUES ($1, $2, $3)',
    [id, memo['title'], memo['description']]
  )
end

def update_memo(id, memo)
  db.exec_params(
    'UPDATE memos SET title = $1, description = $2 WHERE id = $3',
    [memo['title'], memo['description'], id]
  )
end

def delete_memo(id)
  return unless uuid?(id)

  db.exec_params('DELETE FROM memos WHERE id = $1', [id])
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

  id = SecureRandom.uuid
  create_memo(id, @memo)

  redirect "/memos/#{id}"
end

patch '/memos/:id' do
  @id = params['id']
  memo = find_memo(@id)
  if memo.nil?
    status 404
    return erb :not_found
  end

  @memo = memo_params
  @errors = []

  if @memo['title'].strip.empty?
    @errors << 'タイトルを入力してください'
    status 422
    return erb :edit
  end

  update_memo(@id, @memo)

  redirect "/memos/#{@id}"
end

delete '/memos/:id' do
  delete_memo(params['id'])

  redirect '/memos'
end
