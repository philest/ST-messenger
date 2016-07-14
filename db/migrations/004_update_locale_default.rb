Sequel.migration do
	up do
		alter_table(:users) do
			drop_column :locale
			add_column :locale, String, default: 'en'
		end
	end

	down do
		alter_table(:users) do
			drop_column :locale
			add_column :locale, String, default: 'en_US'
		end
	end

end