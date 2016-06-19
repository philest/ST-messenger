Sequel.migration do
  change do
    create_table(:schema_info) do
      Integer :version, :default=>0, :null=>false
    end
    
    create_table(:stories) do
      primary_key :id
      String :title, :text=>true
      String :url, :text=>true
      Integer :num_pages
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true
      String :phone, :text=>true
      String :fb_id, :text=>true
      Integer :story_number, :default=>0
      String :language, :default=>"English", :text=>true
      DateTime :send_time, :default=>DateTime.parse("2016-06-18T23:00:00.000000000+0000")
      String :timezone, :default=>"Eastern Time (US & Canada)", :text=>true
      DateTime :enrolled_on
      DateTime :updated_at
      
      index [:fb_id], :name=>:users_fb_id_key, :unique=>true
      index [:phone], :name=>:users_phone_key, :unique=>true
    end
  end
end
