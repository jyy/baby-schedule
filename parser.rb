require 'erb'
require 'set'
require 'time'
require 'date'

String.class_eval do
  def to_month_day
    date = Date.strptime(to_s, '%m/%d/%Y')
    return date.mon.to_s + "/" + date.day.to_s
  end
  
  def to_day_month_year
    date = Date.strptime(to_s, '%m/%d/%Y')
    return date.day.to_s + "/" + date.mon.to_s + "/" + date.year.to_s
  end
end

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
    @date =  date
    @events = Array.new
  end
  
  def addEvent(event)
    events << event
  end
end

class ScheduleDates
  attr_accessor :dates
  
  def initialize(dates)
    @dates = Array.new(dates)
  end
  
  def get_binding
    binding()
  end
end

relevant = Set.new ["Nurse", "Sleep", "Diaper", "Bottle"]
ascending = Array.new
csvFile = File.new("activities.csv", "r")
while (line = csvFile.gets)
  tokens = line.split(',')
  if relevant.include?(tokens[0])
    ascending.insert(0, tokens)
  end
end

startOfEventValues = Set.new ["Started bottle", "Start Nursing left", "Start Nursing right", "Fell asleep"]
datesHash = Hash.new
lastSeenStartTokens = Hash.new
ascending.each do |tokens|
  dateString = tokens[1]
  
  if datesHash.has_key?(dateString)
    date = datesHash[dateString]
  else
    date = ScheduleDate.new(dateString.to_month_day)
    datesHash[dateString] = date
  end
  
  type = tokens[0]
  lineTime = Time.parse(dateString.to_day_month_year + " " + tokens[2])
  if (type == "Diaper")
    date.addEvent(Event.new(type, lineTime, lineTime))
    next
  end
  
  startTokens = lastSeenStartTokens[type]
  if startTokens == nil
    lastSeenStartTokens[type] = tokens
    next
  else
    startTime = Time.parse(startTokens[1].to_day_month_year + " " + startTokens[2])
    endTime = Time.parse(tokens[1].to_day_month_year + " " + tokens[2])
    
    if startTime.day != endTime.day
      endOfStartDay = Time.mktime(startTime.year, startTime.mon, startTime.day, 23, 59, 59)
      startOfEndDay = Time.mktime(endTime.year, endTime.mon, endTime.day)
      date.addEvent(Event.new(type, startTime, endOfStartDay))
      date.addEvent(Event.new(type, startOfEndDay, endTime))
    else
      date.addEvent(Event.new(type, startTime, endTime))
    end
    lastSeenStartTokens[type] = nil
  end
end

dates = ScheduleDates.new(datesHash.values)

file = File.open("baby-schedule.template", "rb")
template = file.read

renderer = ERB.new(template)
output = renderer.result(dates.get_binding)

outputFile = File.new("baby-schedule.html", "w")
outputFile.write(output)
outputFile.close
