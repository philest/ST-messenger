#workers Integer(ENV['WEB_CONCURRENCY'] || 1) 			# one process for now
workers 1
# threads_count = Integer(ENV['PUMA_MAX_THREADS'] || 4)	# 16 is puma default I think
threads_count = 1
threads 0, threads_count # min = 0, max = threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 5000
environment ENV['RACK_ENV'] || 'development'

# on_worker_boot do

# end
