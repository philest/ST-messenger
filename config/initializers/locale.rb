require 'i18n' 
# Where the I18n library should search for translation files
I18n.load_path += Dir["#{File.dirname(__FILE__)}/../locales/*.{rb,yml}"]
# I18n.backend.load_translations
I18n.default_locale = 'en'
# I18n.locale = 'en'

# puts I18n.t('scripts.buttons.window_text').to_s
# puts I18n.t('scripts.teacher_intro').to_s
# puts I18n.t('scripts.buttons.thanks').to_s
# puts I18n.t('scripts.buttons.title').to_s
# puts I18n.t('scripts.buttons.tap').to_s

# I18n.locale = 'es'

# puts I18n.t('scripts.buttons.window_text').to_s
# puts I18n.t('scripts.teacher_intro').to_s
# puts I18n.t('scripts.buttons.thanks').to_s
# puts I18n.t('scripts.buttons.title').to_s
# puts I18n.t('scripts.buttons.tap').to_s