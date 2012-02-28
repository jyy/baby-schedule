#!/usr/bin/env ruby

require 'erb'
require 'set'
require 'time'
require 'date'

class Event
  attr_accessor :type, :length, :start
   
  def initialize(type, startTime, endTime)
    @type = type.downcase
    
    startOfDay = Time.mktime(startTime.year, startTime.month, startTime.day)
    @start = secToPercentage(startTime.tv_sec - startOfDay.tv_sec)    
    
    if startTime == endTime
      @length = "2px"
    else
      @length = secToPercentage(endTime.tv_sec - startTime.tv_sec)
    end

  end
  
  def secToPercentage(seconds)
    return ((seconds / 60) / 1440.0 * 100).to_s() + "%"
  end
end

class ScheduleDate
  attr_accessor :date, :events
  
  def initialize(date)
    #date has format MM/DD/YYYY
    @date = date[0, 2].to_i.to_s + "/" + date[3, 2].to_i.to_s
    @events = Array.new
  end
  
  def addEvent(event)
    events << event
  end
end

class ScheduleDates
  attr_accessor :dates
  
  def initialize()
    @dates = Array.new
  end

  def add(date)
    dates << date
  end

  def get_binding
    binding()
  end
end

def timeToKey(time)
  month = time.mon < 10 ? "0" + time.mon.to_s : time.mon.to_s
  day = time.day < 10 ? "0" + time.day.to_s : time.day.to_s
  return month + "/" + day + "/" + time.year.to_s
end

def createTime(dateString, timeString)
  #date has format MM/DD/YYYY
  #time has format H:MM AM/PM
  month = dateString[0, 2].to_i
  day = dateString[3, 2].to_i
  year = dateString[6, 4].to_i
  
  split = timeString.split(' ')
  hour = split[0].split(':')[0].to_i
  min = split[0].split(':')[1].to_i

  if split[1] == "PM" and hour != 12
    hour = hour + 12
  elsif split[1] == "AM" and hour == 12
    hour = 0
  end

  return Time.mktime(year, month, day, hour, min)
end

relevant = Set.new ["Nurse", "Sleep", "Diaper", "Bottle"]
ascending = Array.new
csvFile = File.new("activities.csv", "r")
datesHash = Hash.new
descendingKeyOrder = Array.new
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
ascending.each do |tokens|
  date = datesHash[tokens[1]]

  type = tokens[0]
  lineTime = createTime(tokens[1], tokens[2])
  if type == "Diaper"
    date.addEvent(Event.new(type, lineTime, lineTime))
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
  else
    date.addEvent(Event.new(type, startTime, endTime))
  end
  lastSeenStartTokens[type] = nil
end

dates = ScheduleDates.new
descendingKeyOrder.each do |key|
  dates.add(datesHash[key])
end

file = File.open("baby-schedule.template", "rb")
template = file.read

renderer = ERB.new(template)
output = renderer.result(dates.get_binding)

outputFile = File.new("baby-schedule.html", "w")
outputFile.write(output)
outputFile.close
