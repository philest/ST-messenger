Sequel.migration do

  up do
    create_table(:admins) do
      primary_key :id
      String :name, :text=>true
      String :first_name, :text=>true
      String :last_name, :text=>true
      String :email, :text=>true
      String :phone, :text=>true
      String :password, :text=>true
      DateTime :enrolled_on
      DateTime :updated_at
      foreign_key :school_id, :schools, :key=>[:id]
      String :signature, :text=>true
      String :code, :text=>true
      
      index [:code], :name=>:admins_code_key, :unique=>true
      index [:email], :name=>:admins_email_key, :unique=>true
      index [:phone], :name=>:admins_phone_key, :unique=>true
    end
  end


  # down do
  #   drop_table(:admins)
  # end

end