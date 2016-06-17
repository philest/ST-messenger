#  spec/factories.rb 	                      David McPeek		
# 
#  Define a set of factories for creating test model 
#  instances. 
#  --------------------------------------------------------


FactoryGirl.define do
  # Needed to make factorygirl compatible with Sequel. Sequel doesn't have a save! method.
  to_create { |instance| instance.save }
  factory :user do
    name   "Fleem Flom"
    sequence(:phone) {|id| "555#{id}"}
    sequence(:fb_id) {|id| "00000000#{id}" }
    send_time DateTime.new(2016, 6, 24, 19)
  end

  factory :story do
    title  "Hungry Croc"
    url    "http://url"
    num_pages 2
  end

end