# require 'aws-sdk'

# if ENV['RACK_ENV'] != 'production'
#   require 'dotenv'
#   Dotenv.load
# end

# Aws.eager_autoload!

# Aws.config.update({
#   region: 'us-east-1',
#   credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
# })

# S3 = Aws::S3::Resource.new(region: 'us-east-1')
