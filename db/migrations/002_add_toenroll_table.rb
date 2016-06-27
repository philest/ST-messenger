Sequel.migration do
	up do
		create_table(:enrollment_queue) do
			primary_key :id
			foreign_key :user_id, :users, :on_delete => :set_null
			Time :created_at
		end

		alter_table(:users) do
			add_foreign_key :enrollment_queue_id, :enrollment_queue, :on_delete => :set_null
		end
	end
	down do
		drop_table(:enrollment_queue)
		alter_table(:users) do
			drop_foreign_key :enrollment_queue_id
		end
	end
end