webpack: bin/webpack-dev-server
camo: CAMO_KEY=abc PORT=5566 CAMO_ENDPOINT_PATH=/camo CAMO_SOCKET_TIMEOUT=90 CAMO_LENGTH_LIMIT=20971520 CAMO_LOGGING_ENABLED=debug CAMO_ALLOWED_HOSTS=safebooru.org,danbooru.donmai.us,yande.re,files.yande.re,konachan.com coffee ../camo/server.coffee
neko: cd ../neko-achievements && mix run --no-halt
faye: node faye.js
sidekiq: bundle exec sidekiq -C config/sidekiq.yml
# faye: RAILS_ENV=development rackup faye.ru -s thin -E production
# clockwork: bundle exec clockwork config/clock.rb
