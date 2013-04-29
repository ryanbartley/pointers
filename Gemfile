source 'https://rubygems.org'

gem 'sinatra'
gem 'data_mapper'

#pusher dependencies
gem 'pusher'
gem 'uuid'

#find out from Rune about this
# disable :protection

# When developing an app locally you can use SQLite which is a relational
# database stored in a file. It's easy to set up and just fine for most
# development situations.
group :development do
  gem 'dm-postgres-adapter'
  #gem 'dm-sqlite-adapter'
  #gem 'shotgun'
end

# Heroku uses Postgres however, so we tell the Gemfile to use Postgres
# in production instead of SQLite.
group :production do
  gem 'dm-postgres-adapter'
#end