Sequel.migration do
  change do
    alter_table(:users) do
      add_column :enrolled_on, Time
      add_column :updated_at, Time
    end
  end
end
# possible columns to add
=begin
Sequel.migration do
  change do
    alter_table(:users) do
      add_column :child_name, String
      add_column :child_age, Integer
      add_column :zip_code, String
      add_column :reading_level, String, :default => "proficient"
      add_column :ethnicity, String
      # add associations to a usage table
      add_column :race, String
      add_column :gender, String
      add_column :spouse, Boolean
      add_column :spouse_name, String
    end

    alter_table(:teachers) do
      add_column :name, String
      add_column :school, String
      add_column :district, String
      add_column :email, String
      add_column :phone, String
      add_column :fb_id, String
    end
  end
end
=end