Sequel.migration do
  change do
    create_table(:stories) do
      primary_key :id
      String :title, :text=>true
      String :url, :text=>true
      Integer :num_pages
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true
      String :phone, :text=>true, :unique => true
      String :fb_id, :text=>true, :unique => true
      Integer :story_number, :default=>0
      String :language, :default=>"English", :text=>true
      seven_o_clock = 19
      utc_offset = 4
      Time :send_time, :default => Time.new(Time.now.year, Time.now.month, Time.now.day, seven_o_clock + utc_offset, 0, 0, 0)
      String :timezone, :default => "EST"
    end
  end
end
