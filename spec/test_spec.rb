# require 'set'


describe "test" do
	it "matches sets right" do
		expect([1, 2].to_set).to eq([1, 2, 2].to_set)
	end 
end