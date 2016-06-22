Sequel.migration do
	up do
		alter_table(:users) do
			drop_column :language
			add_column :locale, String, :default => "en_US"
		end
	end

	down do
		alter_table(:users) do
			drop_column :locale
			add_column :language, String, :default => "English"
		end
	end
end