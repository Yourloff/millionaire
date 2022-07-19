source 'https://rubygems.org'

ruby '2.5.9'

gem 'rails', '~> 4.2.6'

# Удобная админка для управления любыми сущностями
gem 'rails_admin'

gem 'devise', '>= 4.4.0'
gem 'devise-i18n'

gem 'uglifier', '>= 1.3.0'

gem 'jquery-rails'
gem 'twitter-bootstrap-rails'
gem 'font-awesome-rails'
gem 'russian'

group :development, :test do
  gem 'sqlite3', '~> 1.3.13'
  gem 'byebug'
  gem 'rspec-rails', '~> 3.4'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'

  # Гем, который использует rspec, чтобы смотреть наш сайт
  gem 'capybara'

  # Гем, который позволяет смотреть, что видит capybara
  gem 'launchy'
end

group :production do
  gem 'pg', '~> 0.20'
  gem 'rails_12factor'
end
