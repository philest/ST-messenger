Sequel.migration do
  up do
    create_table(:districts) do
      primary_key :id
      String :name, :text=>true
      String :state, :text=>true
      String :county, :text=>true
      DateTime :created_at
      DateTime :updated_at
    end

    create_table(:stories) do
      primary_key :id
      String :title, :text=>true
      String :url, :text=>true
      Integer :num_pages
    end
    
    create_table(:schools) do
      primary_key :id
      String :name, :text=>true
      String :zip_code, :text=>true
      String :address, :text=>true
      String :phone, :text=>true
      String :email, :text=>true
      DateTime :created_at
      DateTime :updated_at
      foreign_key :district_id, :districts, :key=>[:id]
    end
    
    create_table(:school_sessions) do
      primary_key :id
      String :session_type, :text=>true
      DateTime :start_date
      DateTime :end_date
      DateTime :created_at
      DateTime :updated_at
      foreign_key :school_id, :schools, :key=>[:id]
    end
    
    create_table(:teachers, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true
      String :email, :text=>true
      String :phone, :text=>true
      String :fb_id, :text=>true
      String :password, :text=>true
      DateTime :enrolled_on
      DateTime :updated_at
      foreign_key :school_id, :schools, :key=>[:id]
      String :prefix, :text=>true
      String :signature, :text=>true
      
      index [:email], :name=>:teachers_email_key, :unique=>true
      index [:fb_id], :name=>:teachers_fb_id_key, :unique=>true
      index [:phone], :name=>:teachers_phone_key, :unique=>true
    end
    
    create_table(:classrooms) do
      primary_key :id
      DateTime :enrolled_on
      DateTime :updated_at
      foreign_key :teacher_id, :teachers, :key=>[:id]
      foreign_key :school_id, :schools, :key=>[:id]
    end

    create_table(:enrollment_queue) do
      primary_key :id
      Time :created_at
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true
      String :phone, :text=>true
      String :fb_id, :text=>true
      DateTime :send_time, :default=>DateTime.parse("2016-06-22T23:00:00.000000000+0000")
      DateTime :enrolled_on
      DateTime :updated_at
      String :timezone, :default=>"Eastern Time (US & Canada)", :text=>true
      Integer :child_age
      String :child_name, :text=>true
      Integer :reading_level, :default=>0
      String :gender, :text=>true
      foreign_key :classroom_id, :classrooms, :key=>[:id]
      foreign_key :teacher_id, :teachers, :key=>[:id]
      foreign_key :enrollment_queue_id, :enrollment_queue, :key=>[:id]
      Integer :story_number, :default=>1
      String :locale, :default=>"en_US", :text=>true
      String :profile_pic, :text=>true
      
      index [:fb_id], :name=>:users_fb_id_key, :unique=>true
      index [:phone], :name=>:users_phone_key, :unique=>true
    end

    alter_table(:enrollment_queue) do
      add_foreign_key :user_id, :users
    end
    
    create_table(:button_press_logs, :ignore_index_errors=>true) do
      primary_key :id
      DateTime :created_at
      Integer :day_number
      String :sequence_name, :text=>true
      foreign_key :user_id, :users, :key=>[:id]
      
      index [:day_number, :sequence_name]
    end


  end

  down do
    drop_table :button_press_logs
    alter_table(:users) do
      drop_foreign_key :enrollment_queue_id
    end
    alter_table(:enrollment_queue) do
      drop_foreign_key :user_id
    end
    drop_table :users
    drop_table :classrooms
    drop_table :teachers
    drop_table :school_sessions
    drop_table :schools
    drop_table :stories
    drop_table :districts
    drop_table :enrollment_queue
  end

end