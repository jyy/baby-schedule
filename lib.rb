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