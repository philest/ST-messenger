require_relative '../helpers/fb'

class BotWorker 
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
        # enroll user if they are not in the db
        if User.where(fb_id:recipient).first.nil?
          register_user({'id'=>recipient})
        end
        
        # open DB connection to user
        u = User.where(fb_id:recipient).first   

        # log the button anyway...
        b = ButtonPressLog.new(:day_number=>s.script_day, :sequence_name=>sequence)
        u.add_button_press_log(b)

        protected_ids = %w(1084495154927802 1042751019139427 1625783961083197 10209967651611613 10209571935726081)
        
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
          s.run_sequence(recipient, sequence.to_sym)
          
          # looking for updating user's story#/storyday? well it's 
          # actually a clock worker behavior lol sorry
        else
          puts "we've seen this button before..."
        end

      # TODO: do we want an ELSE behavior?
      end
  end
end
