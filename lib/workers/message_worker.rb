require_relative '../helpers/fb'

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

        protected_ids = %w(1084495154927802 1042751019139427 8186897323 1625783961083197 10209967651611613 10209571935726081)
        
        last_sequence_seen = u.state_table.last_sequence_seen

        # check if the sequence request > last sequence seen in DSL ordering
        sequence_seen      = s.sequence_seen?(sequence, last_sequence_seen)

                             # user story# \leq current request AND not seen the sequence?
        numbers_check_out  = u.state_table.story_number <= s.script_day    && !sequence_seen  


        Sidekiq.logger.warn numbers_check_out ? "#{recipient} not yet seen #{sequence}" : "#{recipient} already saw #{sequence}"

        
        # ...but if they didn't already press the button, send sequence
        if   numbers_check_out                 \
          || last_sequence_seen == 'intro'      \
          || last_sequence_seen == 'teachersend' \
          || protected_ids.include?(recipient)
          # TODO: or query?

          # TODO: run this in a worker
          # run the script
          puts "preparing to run sequence..."
          s.run_sequence(recipient, sequence.to_sym)

        else # numbers don't check out for some reason...
          puts "we're not running the sequence, everybody. sorry to those who drove here."
        end
          
      # TODO: do we want an ELSE behavior?
      end
  end
end

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
