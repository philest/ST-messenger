Sequel.migration do
	change do
		alter_table(:users) do
			drop_column :language
			add_column :locale, String, :default => "en_US"
			drop_column :timezone
			add_column :timezone_offset, Integer, :default => -4
		end
	end
end