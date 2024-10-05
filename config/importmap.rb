# config/importmap.rb

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true

# Pin controllers
pin_all_from "app/javascript/controllers", under: "controllers"
