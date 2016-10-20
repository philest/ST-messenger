require 'spec_helper'
require 'rack/test'
require 'timecop'
require 'active_support/time'

# require 'bot'
require 'bot/dsl'
require 'helpers/fb'
require 'workers'


describe "the scripts" do

  context "scripts" do
    before(:each) do

    end
  end

  context "translation" do
    before(:each) do 
      @user = User.create(fb_id: "my_id", first_name: "David", platform: 'fb')
      @fb_scripts = Birdv::DSL::ScriptClient.scripts['fb']
      @fb_scripts.each do |name, script|
        # puts "#{name}: #{script.methods}" 

        allow(script).to receive(:send).and_wrap_original do |original_method, *args, &block|
          fb_id, to_send = args
          usr = User.where(fb_id: fb_id).first
          if !to_send.is_a? Proc
            fb_object = Marshal.load(Marshal.dump(to_send)) 
            begin 
              script.process_txt(fb_object, usr)
              if fb_object.to_s.include? 'translation missing'
                raise "A TRANSLATION IS MISSING! #{fb_object}"
              end
            rescue => e
              raise e
            end
          end
        end

        allow(script).to receive(:delay).and_wrap_original do |original_method, *args, &block|
        end
      end

      @sms_user = User.create(phone: "my_phone", platform: 'sms')
      @sms_scripts = Birdv::DSL::ScriptClient.scripts['sms']

      @sms_scripts.each do |name, script|
        allow(script).to receive(:send_sms).and_wrap_original do |original_method, *args, &block|
          phone, text, last_sequence, next_sequence = args
          begin   
            nuvo_text = script.translate_sms(phone, text)

            if nuvo_text == false or nuvo_text.to_s.include? 'translation missing'
              raise "A TRANSLATION IS MISSING! #{text}"
            end
          rescue => e
            raise e
          end
        end

        allow(script).to receive(:send_mms).and_wrap_original do |original_method, *args, &block|
          phone, img, last_sequence, next_sequence = args
          begin   
            nuvo_img = script.translate_sms(phone, img)

            if nuvo_img == false or nuvo_img.to_s.include? 'translation missing'
              raise "A TRANSLATION IS MISSING! #{img}"
            end
          rescue => e
            raise e
          end
        end

      end

      @feature_user = User.create(phone: "my_feature_phone", platform: 'feature')
      @feature_scripts = Birdv::DSL::ScriptClient.scripts['feature']
      @feature_scripts.each do |name, script|
        allow(script).to receive(:send_sms).and_wrap_original do |original_method, *args, &block|
          phone, text, last_sequence, next_sequence = args
          begin   
            nuvo_text = script.translate_sms(phone, text)

            if nuvo_text == false or nuvo_text.to_s.include? 'translation missing'
              raise "A TRANSLATION IS MISSING! #{text}"
            end
          rescue => e
            raise e
          end
        end

        allow(script).to receive(:send_mms).and_wrap_original do |original_method, *args, &block|
          phone, img, last_sequence, next_sequence = args
          begin   
            nuvo_img = script.translate_sms(phone, img)

            if nuvo_img == false or nuvo_img.to_s.include? 'translation missing'
              raise "A TRANSLATION IS MISSING! #{img}"
            end
          rescue => e
            raise e
          end
        end

      end



      # allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:send).and_wrap_original do |original_method, *args|
      #   fb_id, to_send = args
      #   puts fb_id, to_send
      # end
    end

    it "all fb script send calls request existing pre-translation strings" do
      # puts @fb_scripts['day1'].methods
      # 
      @fb_scripts.each do |name, script|
        script.sequences.each do |name, sequence|
          if name != 'storysequence'
            expect{script.run_sequence('my_id', name.to_sym)}.not_to raise_error
          end
        end
      end
      @user.update(locale: 'es')

      @fb_scripts.each do |name, script|
        script.sequences.each do |name, sequence|
          if name != 'storysequence'
            expect{script.run_sequence('my_id', name.to_sym)}.not_to raise_error
          end
        end
      end

    end

    it "all sms script send_sms/mms calls request existing pre-translation strings" do
      # puts @fb_scripts['day1'].methods
      # 
      @sms_scripts.each do |name, script|
        script.sequences.each do |name, sequence|
          expect{script.run_sequence('my_phone', name.to_sym)}.not_to raise_error
        end
      end
      @sms_user.update(locale: 'es')
      @sms_scripts.each do |name, script|
        script.sequences.each do |name, sequence|
          expect{script.run_sequence('my_phone', name.to_sym)}.not_to raise_error
        end
      end

    end

    it "all feature script send_sms/mms calls request existing pre-translation strings" do
      # puts @fb_scripts['day1'].methods
      # 
      @feature_scripts.each do |name, script|
        script.sequences.each do |name, sequence|
          expect{script.run_sequence('my_feature_phone', name.to_sym)}.not_to raise_error
        end
      end

      @feature_user.update(locale: 'es')
      @feature_scripts.each do |name, script|
        script.sequences.each do |name, sequence|
          expect{script.run_sequence('my_feature_phone', name.to_sym)}.not_to raise_error
        end
      end

    end
    # iterate through all the scripts
    # run process_txt on each and see if there are any fuckups
    # do the same for sms

  end

end