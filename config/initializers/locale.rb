require 'i18n' 
# Where the I18n library should search for translation files
I18n.load_path += Dir["#{File.dirname(__FILE__)}/../locales/*.{rb,yml}"]
# I18n.backend.load_translations
I18n.default_locale = 'en'
# I18n.locale = 'en'