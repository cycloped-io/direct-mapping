#!/usr/bin/env ruby

require 'bundler/setup'
require 'slop'
require 'csv'
require 'progress'
require 'cycr'

# Comment: this script is rather unecessary

options = Slop.new do
  banner "#{$PROGRAM_NAME} -i articles.csv -c classification.csv -o differences.csv\n" +
    "Check if a given article mapping is consistent with its classification"

  on :i=, :input, "File with mapping of articles to Cyc types", required: true
  on :c=, :classification, "Classification of the articles to Cyc types", required: true
  on :o=, :output, "Output file with detected inconsistencies", required: true
  on :p=, :port, "Cyc port", as: Integer
  on :h=, :host, "Cyc host"
end

begin
  options.parse
rescue
  puts options
  exit
end

classification = Hash.new{|h,e| h[e] = [] }
cyc = Cyc::Client.new(port: options[:port],host: options[:port],cache: true)
name_service = Cyc::Service::NameService.new(cyc)

CSV.open(options[:classification],"r:utf-8") do |input|
  input.with_progress do |page,cyc_id|
    term = name_service.find_by_id(cyc_id)
    raise "Missing term #{cyc_id}" if cyc_id.nil?
    classification[page] << term
  end
end

stats = Hash.new(0)
CSV.open(options[:output],'w') do |output|
  CSV.open(options[:input]) do |input|
    input.with_progress do |page,cyc_name|
      term = name_service.find_by_term_name(cyc_name)
      if term.nil?
        #output << ["missing cyc term",page,cyc_name]
        stats[:missing_term] += 1
        next
      end
      types = classification[page]
      if types.empty?
        #output << ["missing classification",page,cyc_name]
        stats[:missing_classification] += 1
        next
      end
      if !types.any?{|t| cyc.with_any_mt{|c| c.genls?(term,t) } || cyc.with_any_mt{|c| c.isa?(term,t) } }
        output << ["incompatible classification",page,cyc_name,*types.map(&:name)]
        stats[:incompatible] += 1
      end
    end
  end
end

puts "Missing term/missing classification/incompatible #{stats[:missing_term]}/#{stats[:missing_classification]}/#{stats[:incompatible]}"
