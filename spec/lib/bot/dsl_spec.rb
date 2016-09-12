require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'
require 'timecop'

describe 'Birdv::DSL::StoryTimeScript' do


  let (:script_obj) {Birdv::DSL::StoryTimeScript.new('examp') do end}

  
  before(:all) do
    ENV['CURRICULUM_VERSION'] = "0"   # for the purposes of this spec
    @aubrey   = '10209571935726081' # aubrey 
    @success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"

    @stub_story = lambda do |recipient, lib, title, num_pages|
      num_pages.times do |i|
        stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
          with(:body => "{\"recipient\":{\"id\":\"#{recipient}\"},\"message\":{\"attachment\":{\"type\":\"image\",\"payload\":{\"url\":\"http://d2p8iyobf0557z.cloudfront.net/#{lib}/#{title}/#{title}#{i+1}.jpg\"}}}}",
              :headers => {'Content-Type'=>'application/json'}).
          to_return(:status => 200, :body => @success, :headers => {})
      end
    end


    @stub_txt = lambda do |text|  
      success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
      stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
       with(:body => "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"text\":\"#{text}\"}}",
            :headers => {'Content-Type'=>'application/json'}).
       to_return(:status => 200, :body => @success, :headers => {})     
    end

    @stub_arb = lambda do |text|  
      success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
      stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
       with(:body => text,
            :headers => {'Content-Type'=>'application/json'}).
       to_return(:status => 200, :body => @success, :headers => {})     
    end   

  end

  context '#assert_keys' do
    # should this fail gracefully?
    it 'fails gracefully when key assertion happens' do
      false
    end
  end

  # testing the button_story generation
  # => # => # => # => 
  # => # => # => # => 
  # => # => # => # => 
  context '#button_story' do
    before(:all) do
      @btn_name = 'poop'
    end

    before(:each) do
      @pb         = script_obj.postback_button('Tap here!', 'dumb_payload')
      @ubt        = script_obj.url_button('Tap here!', 'http://example.com')
    end     

    it 'hash has required properties' do
      btn = script_obj.button_story ({
        name: @btn_name, 
        title: 'my title',
        image_url: "b", 
        subtitle:"c",
        buttons: [@pb, @ubt]
        })

      [:title, :image_url, :subtitle].each do |x|
        expect(btn[:message][:attachment][:payload][:elements][0].key? x).to be true
      end
    end

    it 'registers newly made button' do
      btn = script_obj.button_story ({
        name: @btn_name, 
        image_url: "b", 
        title: 'my title',
        subtitle:"c",
        buttons: [@pb, @ubt]
        })      
      expect(script_obj.button(@btn_name)).to eq(btn)
    end

    it 'does not err when buttons not set' do
      expect{
        script_obj.button_story({
        name:'garbage',
        title: 'poop',
        image_url: "b"      
        }
      )}.not_to raise_error
    end

    context 'when stuff is not set properly, raises an error' do
      it 'raises an error if title not set properly, no buttons' do
        expect{
          script_obj.button_story({
          name:'garbage',
          image_url: "b"      
          }
        )}.to raise_error(ArgumentError)
      end

      it 'raises an error if title and image_url not set properly, no buttons' do
        expect{
          script_obj.button_story({
          name:'garbage'    
          }
        )}.to raise_error(ArgumentError)
      end

      it 'raises an error if title not set properly, with buttons' do
        expect{
        script_obj.button_story ({
        name: @btn_name, 
        image_url: "b", 
        subtitle:"c",
        buttons: [@pb, @ubt]
        })}.to raise_error(ArgumentError)
      end
    end
  end

  # Visual separation :P
  # => # => # => # => 
  # => # => # => # => 
  # => # => # => # => 
  context '#button_normal' do
    before(:all) do
      @btn_name = 'btn_normal_test'
      @txt  = "hey this is window text, which can be much longer than button text"
    end

    it 'hash has required properties' do
      btn = script_obj.button_normal({
        name: @btn_name, 
        window_text: @txt,
        buttons: [@pb, @ubt]
        })

      [:text, :buttons].each do |x|
        expect(btn[:message][:attachment][:payload].key? x).to be true
      end

      expect(btn[:message][:attachment][:payload][:template_type]).to eq 'button'
    end

    it 'registers newly made button' do
      btn = script_obj.button_normal({
        name: @btn_name, 
        window_text: @txt,
        buttons: [@pb, @ubt]
      })      
      expect(script_obj.button(@btn_name)).to eq(btn)
    end

    it 'raises error when buttons not set' do
      expect{
        script_obj.button_normal({
        name: @btn_name,
        window_text: @txt,
        }
      )}.to raise_error
    end

    it 'raises an error if title & buttons not set properly' do
      expect{
        script_obj.button_normal({
        name: @btn_name,
        }
      )}.to raise_error(ArgumentError)
    end
  end


  # Visual separation :P
  # => 
  # => 
  # =>
  context '#send' do
    before(:each) do
      @num_pages    = 2;
      @txt        = "hey this is window text, which can be much longer than button text"
      @lib      = 'day1'
      @title      = 'chomp'
      

      User.create first_name:'Aubrey', last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey
    end

    before(:example, :story) do
      success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
      @stub_story.call(@aubrey, @lib,@title,@num_pages)
    end

    before(:example, :text) do
      success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
        stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
           with(:body => "{\"recipient\":{\"id\":\"#{@aubrey}\"},\"message\":{\"text\":\"#{@txt}\"}}",
                :headers => {'Content-Type'=>'application/json'}).
           to_return(:status => 200, :body => success, :headers => {})
    end   

    it 'sends a send_story!', story: true do
      expect {
        script_obj.send( 
          @aubrey, 
          script_obj.send_story({ 
                  recipient:  @aubrey,
                  library:    @lib,
                  title:      @title,
                  num_pages:  @num_pages,
                  locale: 'en'
                })
          )
      }.not_to raise_error
    end

    it 'sends a text', text: true do
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: 'testing.test_texts'
            })
        )
      }.not_to raise_error
    end
    

    # the use case here is if we do send(send_story{args...}), which doesn't have :text field
    it 'does not error when passed json, but doesn\'t contain json' do


    end

  end

  # check if sequence has already been seen within a given script
  # these are simple unit tests. integration test somewhere else TODO
  # => 
  # => 
  # =>
  context '#sequence_seen?' do
    before(:all) do

      # load a script
      Birdv::DSL::ScriptClient.new_script 'day1', 'fb' do
        day 1
        sequence 'one' do |recipient|
        end
        sequence 'two' do |recipient|
        end
        sequence 'three' do |recipient|
        end       
        sequence 'four' do |recipient|
        end
      end

      @script_copy = Birdv::DSL::ScriptClient.scripts['fb']['day1']
    end

    it 'returns true when last_sequence_seen is nil?' do
      expect(
        @script_copy.sequence_seen?('one', nil)
      ).to eq false
    end

    # TODO: it emails us when some folks have an invalid input
    # it 'emails phil when the DB has invalid input' do
    #   expect{
    #     @script_copy.sequence_seen?('nonexistentsequence', 'one')
    #   }.to EMAIL_SHIT
    # end   

    # should also email phil
    it 'returns true when input is all wrong?' do
      expect(
        @script_copy.sequence_seen?('nonexistentsequence', 'one')
      ).to eq true
    end   


    it 'returns false when have not seen' do
      expect(
        @script_copy.sequence_seen?('two', 'one')
      ).to eq false   

      expect(
        @script_copy.sequence_seen?('four', 'two')
      ).to eq false   
    end

    it 'returns true when have seen' do
      expect(
        @script_copy.sequence_seen?('two', 'one')
      ).to eq false 
    end

    it 'works properly when input is a symbol' do
      expect(
        @script_copy.sequence_seen?(:two, :one)
      ).to eq false   

      expect(
        @script_copy.sequence_seen?(:four, :two)
      ).to eq false   

      expect(
        @script_copy.sequence_seen?(:nonexistentsequence, :one)
      ).to eq true      

    #   expect{
    #     @script_copy.sequence_seen?(:nonexistentsequence, :one)
    #   }.to EMAIL_SHIT
    end
  end

  
  # Visual separation :P
  # => 
  # => 
  # =>
  # note the difference between 'send story...' and 'send send_story'.
  # the former is usually used in a script, the latter not
  context '#send a #story' do
    # TODO    
    # it 'expects certain arguments' do

    # end

    # it 'send correct story when ' do

    # end

    # it 'updates the last_story_read field' do

    # end

    # it 'updates last_story_read_time' do

    # end
  end

  context 'outro message sms', outro_sms: true do
    before(:all) do
      @day1 = Birdv::DSL::ScriptClient.new_script 'day1', 'sms' do; end
      @day2 = Birdv::DSL::ScriptClient.new_script 'day2', 'sms' do; end
      @day3 = Birdv::DSL::ScriptClient.new_script 'day3', 'sms' do; end
      @day4 = Birdv::DSL::ScriptClient.new_script 'day4', 'sms' do; end
      @day5 = Birdv::DSL::ScriptClient.new_script 'day7', 'sms' do; end
      @txt = 'scripts.buttons.window_text[0]'
    end

    before(:each) do
      @phone = '12345'
      @aubrey = User.create(phone: @phone, first_name:'Aubs', last_name:'Wahl', child_name:'Lil Aubs')
    end

    after(:each) do
      Timecop.return
    end

    context 'on day1' do
      it "says 'next Thursday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        text = @day1.translate_sms(@phone, @txt)
        expect(text).to eq "You'll get another story next Thursday!"

        @aubrey.update(locale: 'es')
        text = @day1.translate_sms(@phone, @txt)
        expect(text).to eq "Le enviaré un cuento nuevo el próximo jueves :)" 
      end
    end

    context 'on day2' do 
      it "says 'next Monday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        text = @day2.translate_sms(@phone, @txt)
        expect(text).to eq "You'll get another story next Monday!"

        @aubrey.update(locale: 'es')
        text = @day2.translate_sms(@phone, @txt)
        expect(text).to eq "Le enviaré un cuento nuevo el próximo lunes :)" 
      end

      it "says 'this Thursday' when it's Monday" do
        Timecop.freeze(Time.new(2016, 9, 5, 23, 0, 0, 0))
        text = @day2.translate_sms(@phone, @txt)
        expect(text).to eq "You'll get another story this Thursday!"

        @aubrey.update(locale: 'es')
        text = @day2.translate_sms(@phone, @txt)
        expect(text).to eq "Le enviaré un cuento nuevo este jueves :)" 
      end
    end

    context 'on day4' do
      it "says 'this Tuesday' when it's Monday" do
        Timecop.freeze(Time.new(2016, 9, 5, 23, 0, 0, 0))
        text = @day4.translate_sms(@phone, @txt)
        expect(text).to eq "You'll get another story this Tuesday!"

        @aubrey.update(locale: 'es')
        text = @day4.translate_sms(@phone, @txt)
        expect(text).to eq "Le enviaré un cuento nuevo este martes :)" 
      end
      it "says 'this Thursday' when it's Tuesday" do
        Timecop.freeze(Time.new(2016, 9, 6, 23, 0, 0, 0))
        text = @day4.translate_sms(@phone, @txt)
        expect(text).to eq "You'll get another story this Thursday!"

        @aubrey.update(locale: 'es')
        text = @day4.translate_sms(@phone, @txt)
        expect(text).to eq "Le enviaré un cuento nuevo este jueves :)" 

      end

      it "says 'next Monday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        text = @day4.translate_sms(@phone, @txt)
        expect(text).to eq "You'll get another story next Monday!"

        @aubrey.update(locale: 'es')
        text = @day4.translate_sms(@phone, @txt)
        expect(text).to eq "Le enviaré un cuento nuevo el próximo lunes :)" 
      end
    end





  end

  context 'outro message', outro: true do
    before(:all) do
      # Birdv::DSL::ScriptClient.clear_scripts 
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../workers/test_scripts/*")
        .each {|f| load f }
      @remind_script = Birdv::DSL::ScriptClient.scripts['fb']['remind']
      @day1 = Birdv::DSL::ScriptClient.scripts['fb']['day1']
      @day2 = Birdv::DSL::ScriptClient.scripts['fb']['day2']
      @day3 = Birdv::DSL::ScriptClient.scripts['fb']['day3']
      @day4 = Birdv::DSL::ScriptClient.scripts['fb']['day4']
      @day7 = Birdv::DSL::ScriptClient.scripts['fb']['day7']

      @txt = 'scripts.buttons.window_text[0]'
      @fb_object = @day1.text({text:@txt}) 
      puts @fb_object.inspect 
    end

    before(:each) do
      @aubrey   = User.create(fb_id: '10209571935726081', first_name:'Aubs', last_name:'Wahl', child_name:'Lil Aubs')
    end
    # also have to test for sms....
    # it 'loaded the scripts' do
    #   puts @day1.inspect, @day2.inspect, @day3.inspect, @day7.inspect, @aubrey.inspect
    # end

    context 'on day1' do
      it "says 'next Thursday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day1.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story next Thursday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day1.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo el próximo jueves :)" 
        # "Le enviaré un cuento nuevo este jueves :)"

        # - "Le enviaré un cuento nuevo el próximo __DAY__ :)"
      end
    end

    context 'on day2' do 
      it "says 'next Monday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day2.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story next Monday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day2.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo el próximo lunes :)"
      end


      it "says 'this Thursday' when it's Monday" do
        Timecop.freeze(Time.new(2016, 9, 5, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day2.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story this Thursday!"


        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day2.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo este jueves :)"
      end
    end

    context 'on day3' do
      it "says 'next Monday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day3.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story next Monday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day3.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo el próximo lunes :)"

      end
      it "says 'this Thursday' when it's Monday" do
        Timecop.freeze(Time.new(2016, 9, 5, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day3.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story this Thursday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day3.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo este jueves :)"

      end
    end

    context 'on day4' do
      it "says 'this Tuesday' when it's Monday" do
        Timecop.freeze(Time.new(2016, 9, 5, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day4.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story this Tuesday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day4.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo este martes :)"

      end
      it "says 'this Thursday' when it's Tuesday" do
        Timecop.freeze(Time.new(2016, 9, 6, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day4.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story this Thursday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day4.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo este jueves :)"

      end

      it "says 'next Monday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day4.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story next Monday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day4.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo el próximo lunes :)"

      end
    end

    context 'on day7' do
      it "says 'this Tuesday' when it's Monday" do
        Timecop.freeze(Time.new(2016, 9, 5, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day7.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story this Tuesday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day7.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo este martes :)"

      end
      it "says 'this Thursday' when it's Tuesday" do
        Timecop.freeze(Time.new(2016, 9, 6, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day7.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story this Thursday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day7.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo este jueves :)"
      end

      it "says 'next Monday' when it's Thursday" do
        Timecop.freeze(Time.new(2016, 9, 8, 23, 0, 0, 0))
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day7.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "You'll get another story next Monday!"

        @aubrey.update(locale: 'es')
        fb_object = Marshal.load(Marshal.dump(@fb_object))
        @day7.process_txt(fb_object, @aubrey)
        expect(fb_object[:message][:text]).to eq "Le enviaré un cuento nuevo el próximo lunes :)"

      end
    end
  end



  # Visual separation :P
  # => 
  # => 
  # =>
  # the success of these tests is verified by making the corrext HTTP request
  context 'name replacement stuff', text_replace: true do
    before(:all) do
      # @txt = "__PARENT__||__CHILD__||__TEACHER__"
      @txt = 'testing.name_codes'
      @lib        = 'day1'
      @title      = 'chomp'
      @aubrey   = '10209571935726081' # aubrey
      
      @estohb = lambda do |text|  
        success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
        stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
             with(:body => "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"text\":\"#{text}\"}}",
                  :headers => {'Content-Type'=>'application/json'}).
             to_return(:status => 200, :body => @success, :headers => {})     
      end
    end


    # TODO: make this a webmock error
    it 'has no problem the the user is missing first_name' do
      # stub the request with the expected body :)
      @estohb.call '||Lil||Mr. McEsterWahl'
      u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey
      t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
      t.add_user u
      User.where(fb_id:@aubrey).first.update first_name: nil
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: @txt })
        )
      }.not_to raise_error      
    end

    it 'has no problem the the user is missing last_name' do
      @estohb.call 'Aubrey||Lil||Mr. McEsterWahl'
      u = User.create  child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
      t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
      t.add_user u
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: @txt })
        )
      }.not_to raise_error  
    end

    it 'has no problem the the user is missing last/first_name' do
      @estohb.call '||Lil||Mr. McEsterWahl'
      u = User.create child_name:'Lil Aubs', fb_id: @aubrey
      t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
      t.add_user u      
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: @txt })
        )
      }.not_to raise_error  
    end

    it 'renders the teacher, parent, and child names when all set' do
      @estohb.call 'Aubrey||Lil||Mr. McEsterWahl'
      u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
      t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
      t.add_user u      
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: @txt })
        )
      }.not_to raise_error  
    end

    it 'properly render just the child name, nothing else set' do
      @estohb.call '||Lil||StoryTime'
      u = User.create child_name:'Lil Aubs', fb_id: @aubrey
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: @txt })
        )
      }.not_to raise_error  
    end

    it 'works when user has no teacher' do
      @estohb.call 'Aubrey||Lil||StoryTime'
      u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: @txt })
        )
      }.not_to raise_error  
    end   
    it 'works when teacher has no signature' do
      @estohb.call 'Aubrey||Lil||StoryTime'
      u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
      t = Teacher.create email:'poop@pee.com', signature: nil
      t.add_user u      
      expect {
        script_obj.send(
          @aubrey,
          script_obj.text({ text: @txt })
        )
      }.not_to raise_error  
    end       
  end 




  # Visual separation :P
  # => 
  # => 
  # =>
  # 
  context '#register_sequence' do
    before(:all) do
      @register_dumb_script = lambda do |name, return_str, script|
        script.sequence name do |recipient|
          return_str
        end       
      end
    end

    it 'registers correct number of sequences' do
      u = User.create(fb_id:@aubrey)    
      @register_dumb_script.call('seq1','a', script_obj)
      @register_dumb_script.call('seq1','b', script_obj)
      @register_dumb_script.call('seq1','c', script_obj)
      @register_dumb_script.call('seq2','d', script_obj)

      expect(script_obj.num_sequences).to eq(2)
      expect(script_obj.run_sequence(@aubrey,'seq1')).to eq('c')
      expect(script_obj.run_sequence(@aubrey,'seq2')).to eq('d')
    end

    it 'overwriting a sequence screws up :init' do
      u = User.create(fb_id:@aubrey)    
      @register_dumb_script.call('seq1','a', script_obj)
      @register_dumb_script.call('seq1','b', script_obj)
      @register_dumb_script.call('seq1','c', script_obj)
      @register_dumb_script.call('seq2','d', script_obj)
      expect(script_obj.run_sequence(@aubrey, :init)).to eq('a')
    end

    it 'errs when fallatious sequence, also DB is not updated' do
      u = User.create(fb_id: @aubrey)   
      old = u.state_table.last_sequence_seen
      
      # should change the last_sequence_seen
      expect{
        @register_dumb_script.call('seq1','a', script_obj)
        @register_dumb_script.call('seq2','b', script_obj)
        script_obj.run_sequence(@aubrey, :seq1)
      }.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from(nil).to 'seq1'

      # should raise error because fallatious
      expect{
        script_obj.run_sequence(@aubrey, :pee)
      }.not_to raise_error(NoMethodError)

      # should not have changed last_sequence_seen
      expect(User.where(fb_id:@aubrey).first.state_table.last_sequence_seen).to eq('seq1')
    end
  end




  # Visual separation :P
  # =>  
  # => 
  # =>
  # making sure that we play nicely with scripts
  # basically, we're running a larger part of stack
  context 'when #send, the DB should be updating, and ', script:true do
    before(:all) do

      @make_aubrey  = lambda do
        User.create phone:'3013328953', first_name:'Aubs', last_name:'Wahl', fb_id:@aubrey, child_name:'Lil Aubs'
      end

      @make_teacher  = lambda do
        Teacher.create email:'poop@pee.com', signature: 'Ms. McEsterWahl'
      end


      #load curriculae
      dir = "#{File.expand_path(File.dirname(__FILE__))}/test_curricula/"
      Birdv::DSL::Curricula.load(dir, absolute=true)      

      # load a script
      @cli = Birdv::DSL::ScriptClient
      @cli.new_script 'day1' do
        button_story({
          name:     'tap_here',
          title:    "scripts.buttons.title",
          image_url:'scripts.buttons.story_img_url', 
          buttons:  [postback_button('scripts.buttons.tap', script_payload(:scratchstory))]
        })
        button_normal({
          name:        'thanks',
          window_text: "scripts.buttons.window_text[0]",
          buttons:      [postback_button('scripts.buttons.thanks', script_payload(:yourwelcome))]
        })      
        sequence 'firsttap' do |recipient|
          txt = "scripts.teacher_intro"
          send recipient, text({text: txt})
          send recipient, button({name:'tap_here'}) 
        end
        sequence 'scratchstory' do |recipient|
          send recipient, story()
          img_1 = "http://d2p8iyobf0557z.cloudfront.net/day1/scroll_up.jpg"
          send recipient, picture({url: img_1})
          send recipient, text({text: 'scripts.buttons.window_text[0]'})
        end
        sequence 'yourwelcome' do |recipient|
          send recipient, text({text: "scripts.buttons.welcome"})
        end         
      
      end #=>END @cli.new_script 'day1' do

      @cli.new_script 'day2' do
        button_story({
          name:     'tap_here',
          title:    "scripts.buttons.title",
          image_url:'scripts.buttons.story_img_url', 
          buttons:  [postback_button('scripts.buttons.tap', script_payload(:story))]
        })

        button_normal({
          name:        'thanks',
          window_text: "scripts.buttons.window_text[0]",
          buttons:      [postback_button('scripts.buttons.thanks', script_payload(:yourwelcome))]
        })      

        sequence 'differentfirst' do |recipient|
          txt = "scripts.teacher_intro"
          send recipient, text({text: txt})
          send recipient, button({name:'tap_here'}) 
        end
        sequence 'story' do |recipient|
          send recipient, story 
          img_1 = "http://d2p8iyobf0557z.cloudfront.net/day1/scroll_up.jpg"
          send recipient, picture({url: img_1})
          send recipient, button({name: 'thanks'})
        end
        sequence 'yourwelcome' do |recipient|
          send recipient, text({text: "scripts.buttons.welcome"})
        end         
      
      end #=>END @cli.new_script 'day1' do      
      @s = @cli.scripts['fb']
    end #=>END before(:all) do

    context 'when updating last_sequence_seen it' do
      let (:u) {@make_aubrey.call}
      let (:t) {@make_teacher.call}
      before(:example) do
        t.add_user u

        # init sequence
        b1 = "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"generic\",\"elements\":[{\"title\":\"Let's read tonight's story.\",\"image_url\":\"https://s3.amazonaws.com/st-messenger/day1/coon/coon-button.jpg\",\"subtitle\":\"\",\"buttons\":[{\"type\":\"postback\",\"title\":\"Tap here!\",\"payload\":\"day1_scratchstory\"}]}]}}}}"
        @stub_txt.call("Hi Aubs, this is StoryTime. We'll be sending you free books for you and your child :)")
        @stub_arb.call(b1)

        # scratchstory sequence
        b2 = "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"attachment\":{\"type\":\"image\",\"payload\":{\"url\":\"http://d2p8iyobf0557z.cloudfront.net/day1/scroll_up.jpg\"}}}}"
        b3 = "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"button\",\"text\":\"You'll get another story next week. You both are doing great! :)\",\"buttons\":[{\"type\":\"postback\",\"title\":\"Thank you!\",\"payload\":\"day1_yourwelcome\"}]}}}}"      
        @stub_arb.call(b2)
        @stub_arb.call(b3)
      end

      it 'updates last sequence seen, nil->init->scratchstory', scratchstory:true do
        pgs = Birdv::DSL::Curricula.get_version(0)[0][2]
        expect(pgs).to eq(2)  # only two pages of coon story
        expect(User.where(fb_id:@aubrey).first.state_table.story_number).to eq(0)
        expect(User.where(fb_id:@aubrey).first.curriculum_version).to eq(0)
        @stub_story.call(@aubrey, "day1","coon", pgs)
        @stub_txt.call("You'll get another story next Thursday!")
        #@stub_story.call(@aubrey, "day1","bird", 8)
        expect {
          @s['day1'].run_sequence(@aubrey, :init)
        }.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from(nil).to ('init')

        expect {
          @s['day1'].run_sequence(@aubrey, :scratchstory)
        }.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from('init').to ('scratchstory')      
      end

    end

    it 'sends the right story' do
      @make_aubrey.call
      @stub_story.call(@aubrey, 'day1', 'coon', 2)
      script = @s['day1']
      expect {
          script.send(@aubrey, script.story())
        }.not_to raise_error
    end

    it 'does not confuse last_sequence with last story_read' do
      @stub_txt.call("You're welcome :)")
      @make_aubrey.call
      s1 = @s['day1']
      s2 = @s['day2']
      expect {
          @stub_story.call(@aubrey, 'day1', 'coon', 2)
          s1.send(@aubrey, s1.story())
          @stub_story.call(@aubrey, 'day1', 'cook', 11)
          s2.send(@aubrey, s2.story())
          @stub_story.call(@aubrey, 'day1', 'scratch', 6)
          s2.send(@aubrey, s2.story())
          s2.run_sequence(@aubrey, 'yourwelcome')
      }.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from(nil).to('yourwelcome')

      # expect(User.where(fb_id:@aubrey).first.state_table.story_number).to eq(1)

    end
  end #=>END context 'when #send, the DB should be updated' do
end

