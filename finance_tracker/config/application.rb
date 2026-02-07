require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_support/railtie"

Bundler.require(*Rails.groups)

module FinanceTracker
  class Application < Rails::Application
    config.load_defaults 7.0
    config.api_only = false
    config.eager_load_paths << Rails.root.join("app")
  end
end
