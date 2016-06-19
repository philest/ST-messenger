Sequel.migration do
  change do

    add_table(:teachers) do
      primary_key :id
      add_column :name, String
      add_column :school_id, Integer

      add_column :email, String
      add_column :phone, String
      add_column :fb_id, String
    end

    add_table(:classrooms) do
      primary_key :id
      add_column :teacher_id, Integer
      add_column :school_id, Integer

    end

    add_table(:schools) do
      primary_key :id
      add_column :name, String
      add_column :district_id, Integer
      add_column :zip_code, String
      add_column :address, String
      add_column :phone, String
    end

    add_table(:districts) do
      primary_key :id
      add_column :name, String
      add_column :state, String
      add_column :county, String
    end

    add_table(:school_sessions) do
      primary_key :id
      add_column :session_type, String
      add_column :start_date, Time
      add_column :end_date, Time
      add_column :school_id, Integer
    end

    alter_table(:users) do
      add_column :child_age, Integer
      add_column :child_name, String
      add_column :classroom_id, Integer
      add_column :reading_level, String, :default => "proficient"
      add_column :gender, String
      add_column :teacher_id, Integer
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