require_relative '../helpers/fb'


class GenericMethodWorker
  include Sidekiq::Worker
  include Facebook::Messenger::Helpers
  sidekiq_options :retry => 1, 
                  unique: :until_and_while_executing, 
                  unique_expiration: 4
                  
  def perform(&block)
    if block_given?
      instance_exec(&block)
    else
      puts "not block given"
    end
  end
end

class MessageWorker 
  include Sidekiq::Worker
  include Facebook::Messenger::Helpers
  sidekiq_options :retry => 1, 
                  unique: :until_and_while_executing, 
                  unique_expiration: 4

  def perform(recipient, script_name, sequence, platform='fb')

      # load script
      s = Birdv::DSL::ScriptClient.scripts[platform][script_name]

      Sidekiq.logger.warn(s.nil? ? "couldn't find script #{script_name}" : "about to send #{script_name}" )

      if not s.nil?

        case platform
        when 'fb'
          # enroll user if they are not in the db
          if User.where(fb_id:recipient).first.nil?
            register_user({'id'=>recipient})
            # it'll be 0, so change to 1 b/c we're not running StartDayWorker which updates the storynumber
            # though, come to think of it, this situation shouldn't happen because if a user gets to MessageWorker
            # without existing in the db, then they'll press the "Get Started" button which will trigger 
            # the StartDayWorker event. Yay! 
            User.where(id:recipient).first.update(story_number: 1)
          end
          
          # open DB connection to user
          u = User.where(fb_id:recipient).first   

          # log the button anyway...
          b = ButtonPressLog.new(:day_number=>s.script_day, :sequence_name=>sequence)
          u.add_button_press_log(b)

        when 'sms'
          puts "looking for #{recipient} phone in MessageWorker"
          u = User.where(phone:recipient).first
          if u.nil? then 
            puts "user with phone #{recipient} doesn't exist bro"
            return 
          end
          
        when 'demo'
          puts "running demo in MessageWorker..."
        end

        # TODO: run this in a worker
        # run the script
        puts "preparing to run sequence..."
        s.run_sequence(recipient, sequence.to_sym)
          
      # TODO: do we want an ELSE behavior?
      end
  end
end
