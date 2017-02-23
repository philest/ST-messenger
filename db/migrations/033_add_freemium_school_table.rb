Sequel.migration do
  up do
    create_table(:freemium_schools) do
      primary_key :id
      String :name, :text=>true
      String :signature
      String :zip_code, :text=>true
      String :address, :text=>true
      String :phone, :text=>true
      String :email, :text=>true
      String :state, :text=>true
      String :city, :text=>true
      String :plan, :text=>true, default: 'free'
      Float :tz_offset
      DateTime :created_at
      DateTime :updated_at
      foreign_key :district_id, :districts, :key=>[:id]
    end
  end

  down do
    drop_table(:freemium_schools)
  end

end