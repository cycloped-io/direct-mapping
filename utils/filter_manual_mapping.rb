#!/usr/bin/env ruby

require 'bundler/setup'
require 'set'
require 'slop'
require 'csv'
require 'rdf'
require 'rdf/turtle'
require 'progress'
require 'uri'

options = Slop.new do
  banner "#{$PROGRAM_NAME} -i classification.nt -m manual.csv -o filtered.csv\n" +
    "From classification file select only entries that are present in manual mapping"

  on :i=, :input, "File with classification of articles into Cyc taxonomy (NT)", required: true
  on :m=, :mapping, "Manual mapping of articles to Cyc types (CSV)", required: true
  on :o=, :output, "Output file with filtered classification (CSV)", required: true
end

begin
  options.parse
rescue
  puts options
  exit
end

def from_url(url)
  url.to_s[url.to_s.rindex("/")+1..-1]
end

def from_db_pedia(url)
  URI.unescape(from_url(url))
end

articles = Set.new
CSV.open(options[:mapping],"r:utf-8") do |input|
  input.with_progress do |article_name,umbel_name|
    articles << article_name
  end
end

CSV.open(options[:output],'w') do |output|
  File.open(options[:input]) do |input|
    Progress.start(input.size)
    reader = RDF::Turtle::Reader.new(input, format:  :n3)
    reader.each_triple do |subject,_,object|
      subject = from_db_pedia(subject)
      object = from_url(object)
      output << [subject,object] if articles.include?(subject)
      Progress.set(input.pos)
    end
    Progress.stop
  end
end
