require_relative '../helpers/fb'
require_relative '../helpers/contact_helpers'
require_relative '../helpers/name_codes'
require_relative '../workers/message_worker'
# the translation files
require_relative '../../config/initializers/locale' 
require_relative '../helpers/twilio_helpers'
require_relative 'fb_dsl.rb'
require_relative 'sms_dsl.rb'

module Birdv
  module DSL
    class ScriptClient
      @@scripts = {
        'fb' => {},
        'sms' => {},
        'feature' => {}
      }

      def self.new_script(script_name, platform='fb', &block)
        # puts "adding #{script_name} - platform #{platform} to thing"
        @@scripts[platform][script_name] = StoryTimeScript.new(script_name, platform, &block)
      end

      def self.scripts
        @@scripts
      end

      def self.clear_scripts
        @@scripts = {
          'fb' => {},
          'sms' => {},
          'feature' => {}
        }
      end 
    end
  end
end

module Birdv
  module DSL
    class StoryTimeScript
      include ContactHelpers
      include NameCodes

      attr_reader :script_name, :script_day, :num_sequences, :sequences, :platform
      

      def initialize(script_name, platform='fb', &block)
        @fb_objects     = {}
        @sequences      = {}
        @script_name    = script_name # TODO how do we wanna do this?
        @platform       = platform
        @num_sequences  = 0
        day             = script_name.scan(/\d+/)[0]

        # modularization...
        if platform == 'fb'
          self.extend(FB)
        elsif platform == 'sms' or platform == 'feature'
          self.extend(Texting)
        end

        # TODO: something about this
        @script_day = !day.nil? ? day.to_i : 0

        instance_eval(&block)
        return self
      end


      def register_sequence(sqnce_name, block)
        sqnce = sqnce_name.to_sym

        # check if this sqnce was already registered
        already_registered = @sequences.has_key?(sqnce)

        # register sqnce and index it
        @sequences[sqnce]  = [block, @num_sequences]

        if @sequences[:init] == nil
          @sequences[:init] = @sequences[sqnce]
        end

        # if sqnce wasn't previously registered, increment the number of registered sequences
        warning = 'WARNING: you already registered that sequence :('
        already_registered ? puts(warning) : @num_sequences = @num_sequences+1 
      end

      def sequence_seen? (sqnce_to_send_name, last_sequence_seen)

        if (last_sequence_seen.nil?)
          return false
        end

        sqnce_new = @sequences[sqnce_to_send_name.to_sym] # TODO: ensure non-sym input is ok
        sqnce_old = @sequences[last_sequence_seen.to_sym]

        # TODO: write spec that ensure nothing bad happens when bade sqnce name given
        if (sqnce_new != nil && sqnce_old != nil)
          if sqnce_new[1] > sqnce_old[1]
            return false
          end
        end

        # assume that we have seen the sqnce already
        return true
      end

      def assert_keys(keys = [], args)
        keys.each{|x| if  !args.key?(x) then raise ArgumentError.new("DSL: need to set :#{x} field") end}
      end


      def day(number)
        @script_day = number
      end

      def script_payload(sequence_name)
        # puts "cool payload: #{@script_name.to_s}_#{sequence_name.to_s}"
        return "#{@script_name.to_s}_#{sequence_name.to_s}"
      end

      def sequence(sqnce_name, &block)
        register_sequence(sqnce_name, block)
      end

      # how do we abstract this?
      def run_sequence(recipient, sqnce_name)
        ret =  instance_exec(recipient, &@sequences[sqnce_name.to_sym][0])

        case @platform
        when 'fb'
          u = User.where(fb_id:recipient).first
        when 'sms', 'feature'
          u = User.where(phone:recipient).first
        end

        if u then # u might not exist because it's a demo
          u.state_table.update(last_sequence_seen: sqnce_name.to_s)
        end
        return ret
        
      rescue => e  
        puts "#{sqnce_name} from script #{@script_name} failed!"
        puts "the known sequences are: #{@sequences}"
        puts e.message  
        puts e.backtrace.join("\n") 
        notify_admins("StoryTime Script error: #{sqnce_name} of #{@script_name} failed!", e.backtrace.join("\n"))
        raise e if ENV['RACK_ENV'] == 'test'
      end

      def delay_inline(time_delay, &block)
        GenericMethodWorker.perform_in(time_delay, &block)
      end


      def delay(*args, time_delay, &block)
        # if block_given?
          # GenericMethodWorker.perform_in(time_delay, &block)
        # else
          recipient, sequence_name = args
          MessageWorker.perform_in(time_delay, recipient, @script_name, sequence_name, platform=@platform)
        # end
      end

      def unsubscribe_demo(recipient)
        u = User.where(fb_id: recipient).first
        if u.nil? then
          u = User.where(phone: recipient).first
          if u.nil? then return end
        end
        u.state_table.update(subscribed?: false)
      end

      def resubscribe_demo(recipient)
        u = User.where(fb_id: recipient).first
        if u.nil? then
          u = User.where(phone: recipient).first
          if u.nil? then return end
        end
        u.state_table.update(subscribed?:true)
      end


      def resubscribe(recipient)
        u = User.where(fb_id: recipient).first
        if u.nil? then
          u = User.where(phone: recipient).first
          if u.nil? then return end
        end
        # case for story 3

        # have to reset everything so the user's back to normal, receiving the same
        # same story as they normally would
        current_story_no = u.state_table.story_number
        u.state_table.update(subscribed?: true,
                             num_reminders: 0,
                             last_story_read?: true,
                             # story_number: (current_story_no - 1),
                             last_script_sent_time: nil,
                             last_reminded_time: nil
                            )
      end

    end
  end
end




# valid generic template format
# message: {
#   attachment: {
#     type: 'template',
#     payload: {
#       template_type: 'generic',
#       elements: [{
#         title: title,
#         image_url: 'image_url is an optional field, but only include if you will use it',
#         subtitle: "you can acutally include subititle but still set it as empty string",
#         buttons: [{you are require to add buttons}]
#       }]
#     }
#   }
# }
