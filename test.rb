require 'i18n'

require_relative 'config/initializers/locale'

I18n.locale = 'en_US'
puts I18n.t('user-response.help')

# I18n.locale = 'spanish'
# puts I18n.t('hello')