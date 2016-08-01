require_relative '../helpers/fb'
require_relative '../helpers/contact_helpers'
require_relative '../workers/message_worker'
# the translation files
require_relative '../../config/initializers/locale' 
require_relative 'fb_dsl.rb'
require_relative 'sms_dsl.rb'

module Birdv
  module DSL
    class ScriptClient
      @@scripts = {
        'fb' => {},
        'sms' => {}
      }

      def self.new_script(script_name, platform='fb', &block)
        puts "adding #{script_name} - platform #{platform} to thing"
        @@scripts[platform][script_name] = StoryTimeScript.new(script_name, platform, &block)
      end

      def self.scripts
        @@scripts
      end

      def self.clear_scripts
        @@scripts = {
          'fb' => {},
          'sms' => {}
        }
      end 
    end
  end
end

module Birdv
  module DSL
    class StoryTimeScript
      include Facebook::Messenger::Helpers 
      include ContactHelpers

      attr_reader :script_name, :script_day, :num_sequences, :sequences, :platform
      STORY_BASE_URL = 'http://d2p8iyobf0557z.cloudfront.net/'

      def initialize(script_name, platform='fb', &block)
        @fb_objects  = {}
        @sequences   = {}
        @script_name = script_name # TODO how do we wanna do this?
        @platform = platform
        @num_sequences = 0
        day          = script_name.scan(/\d+/)[0]

        # modularization...
        if platform == 'fb'
          self.extend(FB)
        elsif platform == 'sms'
          self.extend(SMS)
        end

        # TODO: something about this
        @script_day = !day.nil? ? day.to_i : 0

        instance_eval(&block)
        return self
      end

      # Universal methods:
      # register_sequence
      # sequence_seen?
      # assert_keys
      # day
      # script_payload
      # run_sequence
      # delay
      # translate
      # story

      # FB methods that should GET THE FUCK OUTTA HERE!
      # register_fb_object
      # button
      # process_txt

      # problems with these fb methods
      # register_fb_object
      #   @fb_objects instance variable
      # button
      #   @fb_objects instance var
      # story
      #   @script_day (easy, pass as parameter of function)
      # process_txt
      #   @script_day (pass as parameter, easy)



      def register_fb_object(obj_key, fb_obj)
        puts 'WARNING: overwriting object #{obj_key.to_s}' if @fb_objects.key?(obj_key.to_sym)
        @fb_objects[obj_key.to_sym] =  fb_obj
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
        puts "cool payload: #{@script_name.to_s}_#{sequence_name.to_s}"
        return "#{@script_name.to_s}_#{sequence_name.to_s}"
      end

      def sequence(sqnce_name, &block)
        register_sequence(sqnce_name, block)
      end

      # how do we abstract this?
      def run_sequence(recipient, sqnce_name)
        begin
          ret =  instance_exec(recipient, &@sequences[sqnce_name.to_sym][0])          

          case @platform
          when 'fb'
            u = User.where(fb_id:recipient).first
          when 'sms'
            u = User.where(phone:recipient).first
          end
          

          u.state_table.update(last_sequence_seen: sqnce_name.to_s) if u
          return ret

        rescue => e  
          puts "#{sqnce_name} from script #{@script_name} failed!"
          puts "the known sequences are: #{@sequences}"
          puts e.message  
          puts e.backtrace.join("\n") 
          email_admins("StoryTime Script error: #{sqnce_name} failed!", e.backtrace.join("\n"))
        end
      end

      def button(btn_name)
        if btn_name.is_a? String
          return @fb_objects[btn_name.to_sym]
        elsif btn_name.is_a? Hash 
          # TODO: ensure is not nil?
          return @fb_objects[btn_name[:name].to_sym]
        else
          return @fb_objects[btn_name]
        end
      end


      def delay(recipient, sequence_name, time_delay)
        MessageWorker.perform_in(time_delay, recipient, @script_name, sequence_name, platform=@platform)
      end

      def story(args={})
        create_story(args, @script_day)
      end

      def send( recipient, to_send, type='sms')
        send_helper(recipient, to_send, @script_day, type='sms')
      end

      # translate_mms has moved to contact_helpers.rb
      # send_sms has moved to contact_helpers.rb
      # send_mms has moved to contact_helpers.rb

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
