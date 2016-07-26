require 'csv'
module Birdv
  module DSL
    class Curricula
    	@@curricula = {}
      
      def self.load(dir="../curriculum_versions", absolute=false)

        @@curricula = {}

        # TODO: ensure ending '/'
        if !absolute
          file_path = "#{File.expand_path(File.dirname(__FILE__))}/#{dir}/*"
        else
          file_path = "#{dir}*"
        end
        # using a hash to ensure the correct ordering of the curriculum versions
        Dir.glob(file_path).each do |f|
          puts f
          CSV.foreach(f, headers:true, header_converters: :symbol, :converters => :all) do |row|
            file_base = File.basename(f, ".csv")

            # if file is an integer
            if !(file_base =~ /\A[-+]?\d+\z/).nil?
              curr_version = file_base.to_i
            else
              curr_version = file_base
            end

            # establish index for curriculum version
            @@curricula[curr_version] ||= []
            
            puts "ROW: #{row} of type #{row.class}"
            
            stripped_row = []

            # strip white space if unecesarry whitespace exists
            row.to_hash.values.each do |x|
              stripped_row << (x.is_a?(String) ? x.gsub(/\s/, '') : x)
            end

            @@curricula[curr_version] << stripped_row
          end

        end

        return @@curricula
      end
      
      def self.curricula
        @@curricula
      end


      def curricula
        @@curricula
      end

      def self.get_version(version_num)
      	return @@curricula[version_num]
      end
    end #--> class Curricula
  end #--> module DSL
end #--> module Birdv
