require 'i18n'

require_relative 'config/initializers/locale'

I18n.locale = 'en'
puts I18n.t('hello')

# I18n.locale = 'spanish'
# puts I18n.t('hello')