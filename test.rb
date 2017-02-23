require_relative 'bin/production'
require 'csv'

csv_file = "editedpublic-school-universe-dataset-2014-2015.csv"
i = 0

puts "my asshole"

CSV.foreach(csv_file, headers:true) do |row|
  18578
  if row['PKOFFERED'] != 'Y'
    puts "PREK NOT OFFERED AT THIS SCHOOL!"
    puts "i = #{i}"
    break
  end


  if i == 18578
    break
  end

  school_name = row['SCH_NAME'].gsub(/\bsch\b/i, 'School')
  school_name = school_name.gsub(/\belem\b/i, 'Elementary')

  school_info = {
    signature: school_name,
    name: school_name,
    state: row['STABR'],
    city: row['MCITY'],
    zip_code: row['LZIP'],
    address: row['MSTREET1'],
    plan: 'free',
    phone: row['PHONE'].to_s

  }

  FreemiumSchool.create(school_info)

  puts "row#{i} = #{row.inspect}"

  i += 1 
end

# add all freemium schools from file


