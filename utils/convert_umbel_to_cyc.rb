#!/usr/bin/env ruby

require 'bundler/setup'
require 'slop'
require 'csv'
require 'progress'

# Comment: this script is rather unecessary

options = Slop.new do
  banner "#{$PROGRAM_NAME} -i articles.csv -m umbel_to_cyc.csv -o converted.csv\n" +
    "Convert UMBEL ids to Cyc ids in the direct manual mapping"

  on :i=, :input, "File with manual mapping of articles to UMBEL types", required: true
  on :m=, :mapping, "File with mapping of UMBEL types to Cyc types", required: true
  on :o=, :output, "Output file with mapping converted to Cyc ids", required: true
end

begin
  options.parse
rescue
  puts options
  exit
end

mapping = {}
CSV.open(options[:mapping],"r:utf-8") do |input|
  input.with_progress do |umbel_id,cyc_id,cyc_name|
    mapping[umbel_id] = [cyc_id,cyc_name]
  end
end

missing = 0
CSV.open(options[:output],'w') do |output|
  CSV.open(options[:input]) do |input|
    input.with_progress do |page_name,umbel_id|
      tuple = mapping[umbel_id]
      if tuple.nil?
        missing += 1
        puts umbel_id
        next
      end
      output << [page_name,*tuple]
    end
  end
end

puts "Missing mappings: #{missing}"
