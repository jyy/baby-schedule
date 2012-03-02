#!/usr/bin/env ruby

require 'erb'
require 'set'
require 'time'
require './lib.rb'

if ARGV.length < 1 or ARGV.length > 2
  puts "usage: parser.rb csv_input_file [html_output_file]"
  exit
end

inputFileName = ARGV[0]
outputFileName = ARGV[1] == nil ? "baby-schedule.html" : ARGV[1]
lastReadFileName = "/tmp/baby-schedule-last-read"

if File.exists? lastReadFileName
  lastReadCTime = Time.parse(File.new(lastReadFileName, "r").gets)
  currentInputCTime = File.ctime(inputFileName)
  if lastReadCTime >= currentInputCTime
    puts "Input file is older or the same as last input file"
    exit
  end 
end

File.new(lastReadFileName, "w").puts File.ctime(inputFileName)

relevant = Set.new ["Nurse", "Sleep", "Diaper", "Bottle"]
ascending = Array.new
csvFile = File.new(inputFileName, "r")
datesHash = Hash.new
descendingKeyOrder = Array.new
puts "reading " + inputFileName
while (line = csvFile.gets)
  tokens = line.split(',')
  if relevant.include?(tokens[0])
    ascending.insert(0, tokens)
    scheduleDate = datesHash[tokens[1]]
    if scheduleDate == nil
      datesHash[tokens[1]] = ScheduleDate.new(tokens[1])
      descendingKeyOrder << tokens[1] 
    end
  end
end

startOfEventValues = Set.new ["Started bottle", "Start Nursing left", "Start Nursing right", "Fell asleep"]
lastSeenStartTokens = Hash.new
eventsTotal = 0
ascending.each do |tokens|
  date = datesHash[tokens[1]]

  type = tokens[0]
  lineTime = createTime(tokens[1], tokens[2])
  if type == "Diaper"
    date.addEvent(Event.new(type, lineTime, lineTime))
    eventsTotal += 1
    next
  end
  
  if startOfEventValues.include? tokens[3]
    lastSeenStartTokens[type] = tokens
    next
  end

  startTokens = lastSeenStartTokens[type]
  if startTokens == nil
    next
  end

  startTime = createTime(startTokens[1], startTokens[2])
  endTime = createTime(tokens[1], tokens[2])
    
  if startTime.day != endTime.day
    endOfStartDay = Time.mktime(startTime.year, startTime.mon, startTime.day, 23, 59, 59)
    startOfEndDay = Time.mktime(endTime.year, endTime.mon, endTime.day)
    yesterday = datesHash[timeToKey(startTime)]
    yesterday.addEvent(Event.new(type, startTime, endOfStartDay))
    date.addEvent(Event.new(type, startOfEndDay, endTime))
    eventsTotal += 1
  else
    date.addEvent(Event.new(type, startTime, endTime))
    eventsTotal += 1
  end
  lastSeenStartTokens[type] = nil
end

dates = ScheduleDates.new
descendingKeyOrder.each do |key|
  dates.add(datesHash[key])
end

puts "processed " + eventsTotal.to_s + " events"

file = File.open("baby-schedule.template", "rb")
template = file.read

renderer = ERB.new(template)
output = renderer.result(dates.get_binding)

puts "writing " + outputFileName
outputFile = File.new(outputFileName, "w")
outputFile.write(output)
outputFile.close

puts "complete"
