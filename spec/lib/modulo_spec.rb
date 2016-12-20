require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'
require 'timecop'
require 'workers'

describe 'modulo stories' do
  context "start day worker" do 
    before(:each) do
      @sw = StartDayWorker.new
      @fb_id = 'my_fb_id'
      @user = User.create(fb_id: @fb_id)
      @user.state_table.update(last_story_read?:true, subscribed?:true)

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "calling run_sequence with #{args}"
      end

    end

    context "user has less than total stories" do

        it "updates last_unique_story when getting a new story" do
          $story_count = 5
          @user.state_table.update(story_number: 0)

          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 1
        end

        it "sends a story the normal way" do
          $story_count = 5
          @user.state_table.update(story_number: 0)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day1']).to receive(:run_sequence).once

          Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
          end
        end
    end

    context "user has more than total stories and no new stories" do

        it "does not update last_unique_story when getting an old story" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 5
          @user.state_table.update(story_number: 7, last_unique_story: 5)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.not_to change{@user.state_table.last_unique_story}


        end

        it "sends the correct modulo story" do
          $story_count = 5
          @user.state_table.update(story_number: 7, last_unique_story: 5)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day3']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

        end

        it "updates state_table fields correctly: last_story_read?, story_number" do

        end


        it "chooses day2 when mod is 1" do
          $story_count = 6
          @user.state_table.update(story_number: 12, last_unique_story: 6)
          expect(Birdv::DSL::ScriptClient.scripts['fb']['day2']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end


        end

    end


    context "user has more than total stories and there is one new story" do

        it "updates last_unique_story when getting an old story" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 5)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 6


        end

        it "sends the correct modulo story" do
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 5)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day6']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

        end


        it "updates last_unique_story when getting an old story 2" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 3)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 4


        end

        it "sends the correct modulo story 2" do
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 3)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day4']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

        end


    end


    context "user has more than total stories and there are many new stories" do

        it "updates last_unique_story when getting an old story" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 6
          @user.state_table.update(story_number: 10, last_unique_story: 3)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 4


        end

        it "sends the correct modulo story" do
          $story_count = 6
          @user.state_table.update(story_number: 10, last_unique_story: 3)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day4']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

        end


    end



  end


  # context 'global variable story_count' do
  #   it 'is accessible by the user object' do
  #     my_story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*")
  #       .inject(0) do |sum, n|
  #                   if /\d+\.rb/.match n
  #                     sum + 1
  #                   else  
  #                     sum
  #                   end
  #                 end

  #     puts $story_count
  #     expect($story_count).to eq my_story_count    
  #     expect($story_count).to_not eq 0
  #   end
  # end
end
