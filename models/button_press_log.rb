class ButtonPressLog < Sequel::Model(:button_press_logs)
	plugin :timestamps, :create=>:created_at 
	many_to_one :user
end