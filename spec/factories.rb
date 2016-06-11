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
    phone  "+18186897323"
    fb_id  "12345678"
  end

  factory :story do
    title  "Hungry Croc"
    url    "http://url"
    num_pages 2
  end

end