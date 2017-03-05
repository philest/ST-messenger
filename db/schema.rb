Sequel.migration do
  change do
    create_table(:districts) do
      primary_key :id
      String :name, :text=>true
      String :state, :text=>true
      String :county, :text=>true
      DateTime :created_at
      DateTime :updated_at
    end
    
    create_table(:schema_info) do
      Integer :version, :default=>0, :null=>false
    end
    
    create_table(:stories) do
      primary_key :id
      String :title, :text=>true
      String :url, :text=>true
      Integer :num_pages
    end
    
    create_table(:freemium_schools) do
      primary_key :id
      String :name, :text=>true
      String :signature, :text=>true
      String :zip_code, :text=>true
      String :address, :text=>true
      String :phone, :text=>true
      String :email, :text=>true
      String :state, :text=>true
      String :city, :text=>true
      String :plan, :default=>"free", :text=>true
      Float :tz_offset
      DateTime :created_at
      DateTime :updated_at
      foreign_key :district_id, :districts, :key=>[:id]
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
      String :code, :default=>"read|leer", :text=>true
      String :timezone, :default=>"Eastern Time (US & Canada)", :text=>true
      String :signature, :text=>true
      Float :tz_offset
      Integer :total_users
      Integer :teacher_index, :default=>0
      String :city, :text=>true
      String :state, :text=>true
      String :plan, :default=>"pro", :text=>true
    end
    
    create_table(:admins, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true
      String :first_name, :text=>true
      String :last_name, :text=>true
      String :email, :text=>true
      String :phone, :text=>true
      String :password_digest, :text=>true
      DateTime :enrolled_on
      DateTime :updated_at
      foreign_key :school_id, :schools, :key=>[:id]
      String :signature, :text=>true
      String :code, :text=>true
      Integer :signin_count, :default=>0
      DateTime :notified_on
      Integer :grade
      
      index [:code], :name=>:admins_code_key, :unique=>true
      index [:email], :name=>:admins_email_key, :unique=>true
      index [:phone], :name=>:admins_phone_key, :unique=>true
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
      String :password_digest, :text=>true
      DateTime :enrolled_on
      DateTime :updated_at
      foreign_key :school_id, :schools, :key=>[:id]
      String :prefix, :text=>true
      String :signature, :text=>true
      String :code, :text=>true
      Integer :t_number, :default=>0
      DateTime :notified_on
      Integer :signin_count, :default=>0
      String :first_name, :text=>true
      String :last_name, :text=>true
      Integer :grade
      
      index [:code], :name=>:teachers_code_key, :unique=>true
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
    
    create_table(:button_press_logs, :ignore_index_errors=>true) do
      primary_key :id
      DateTime :created_at
      Integer :day_number
      String :sequence_name, :text=>true
      Integer :user_id
      String :platform, :default=>"fb", :text=>true
      String :script_name, :text=>true
      
      index [:day_number, :sequence_name]
    end
    
    create_table(:enrollment_queue) do
      primary_key :id
      DateTime :created_at
      Integer :user_id
    end
    
    create_table(:state_tables) do
      primary_key :id
      TrueClass :last_story_read?, :default=>false
      DateTime :last_script_sent_time
      String :next_script, :text=>true
      DateTime :next_story_time
      String :series_name, :text=>true
      Integer :series_index, :default=>0
      DateTime :last_reminded_time
      Integer :num_reminders, :default=>0
      TrueClass :subscribed?, :default=>true
      DateTime :last_story_read_time
      Integer :user_id
      String :last_sequence_seen, :text=>true
      DateTime :updated_at
      Integer :story_number, :default=>0
      DateTime :unsubscribed_on
      Integer :last_unique_story, :default=>0
      TrueClass :last_unique_story_read?, :default=>true
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
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
      String :profile_pic, :text=>true
      foreign_key :state_table_id, :state_tables, :key=>[:id]
      String :first_name, :text=>true
      String :last_name, :text=>true
      Integer :curriculum_version, :default=>0
      String :locale, :default=>"en", :text=>true
      foreign_key :school_id, :schools, :key=>[:id]
      String :platform, :default=>"fb", :text=>true
      Float :tz_offset
      String :code, :text=>true
      String :password_digest, :text=>true
      String :email, :text=>true
      String :refresh_token_digest, :text=>true
      String :role, :default=>"parent", :text=>true
      String :class_code, :text=>true
      String :fcm_token, :text=>true
      Integer :app_version_number
      String :reset_password_token_digest, :text=>true
      DateTime :last_refresh_token_iss, :default=>DateTime.parse("1995-07-11T23:00:00.000000000+0000")
      
      index [:code], :name=>:users_code_key, :unique=>true
      index [:email], :name=>:users_email_key, :unique=>true
      index [:fb_id], :name=>:users_fb_id_key, :unique=>true
      index [:phone], :name=>:users_phone_key, :unique=>true
    end
    
    alter_table(:button_press_logs) do
      add_foreign_key [:user_id], :users, :name=>:button_press_logs_user_id_fkey, :key=>[:id]
    end
    
    alter_table(:enrollment_queue) do
      add_foreign_key [:user_id], :users, :name=>:enrollment_queue_user_id_fkey, :key=>[:id]
    end
    
    alter_table(:state_tables) do
      add_foreign_key [:user_id], :users, :name=>:state_tables_user_id_fkey, :key=>[:id]
    end
  end
end
