require 'webrick'
require 'dbi'
config = {
  :Port => 8080,
  :DocumentRoot => '.'
}

server = WEBrick::HTTPServer.new( config )
server.mount_proc "/" do |req, res|
  #DBのデータを表示
  names = []
  dbh = DBI.connect( 'DBI:SQLite3:names.db' )
  dbh.select_all("select * from name_tbl") do |row|
    #DBから読み込みHashでnames配列に追加
    names << {id: row["id"], name: row["name"]}
  end
  dbh.disconnect
  res.body = ERB.new(File.read('list.erb')).result(binding)
end

server.mount_proc "/names" do |req, res|
  #DBにデータ登録
  dbh = DBI.connect('DBI:SQLite3:names.db')
  dbh.do("insert into name_tbl (name) values ('#{req.query["name"]}')")
  dbh.disconnect
  res.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect, '/')
end

server.mount_proc "/names/delete" do |req, res|
dbh = DBI.connect( 'DBI:SQLite3:names.db' )
dbh.do("delete from name_tbl where id=#{req.query["id"]}")
dbh.disconnect
res.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect,'/')
end

server.mount_proc "/names/edit" do |req, res|
    id = req.query["id"]    #edit.erbに渡すため
    name = ""     #edit.erbに渡すため
    dbh = DBI.connect( 'DBI:SQLite3:names.db' )
      dbh.select_all("select name from name_tbl where id=#{id}") do
  |row|
      name = row[0]
    end
    res.body = ERB.new(File.read('edit.erb')).result(binding)
end

server.mount_proc "/names/update" do |req, res|
  dbh = DBI.connect( 'DBI:SQLite3:names.db' )
  dbh.do("update name_tbl set name='#{req.query["name"]}' where id=#{req.query["id"]}")
  dbh.disconnect
    res.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect,'/')
end

trap(:INT) do
  server.shutdown
end
server.start