require 'google/apis/civicinfo_v2'
require 'csv'
require 'erb'
require 'date'
require 'time'
def clean_zipcode(zipcode)
  zip = zipcode.to_s.rjust(5,'0')[0..4]
end

def display_legislators(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody','legislatorLowerBody']
    ).officials
  rescue
    "Search for your information in the officials website"
  end
end

def clean_mobile_number(mobile_number)
  flag = false
  cleansed_number
  if mobile_number.length<10
    flag = true
  elsif mobile_number.length>10
    if mobile_number.to_s[0]=='1'
      cleansed_number = mobile_number[1..10]
      flag = false
    else  
      flag = true
    end
  elsif mobile_number.length==10
    cleansed_number = mobile_number.to_s
    flag = false
  elsif mobile_number.length>11
    flag = true
  end
  if flag
    return "Bad mobile number"
  else
    return clean_mobile_number
  end 
end

def date_max
  file = CSV.open("event_attendees.csv",headers: true,header_converters: :symbol)
  date_hash = {"Sunday" => 0,"Monday" => 0,"Tuesday" => 0,"Wednesday" => 0,"Thursday" => 0,"Friday" => 0,"Saturday" => 0}
  max_date = "Sunday"
  max_count = 0
  file.each do |line|
    d = Date.strptime(line[:regdate].split(" ")[0],'%m/%d/%y')
    x = d.strftime("%A").strip()
    date_hash[x]+=1.to_i
    if date_hash[x].to_i>max_count
      max_date = x
      max_count = date_hash[x].to_i
    end
  end
  return max_date
end 

def time_max
  file = CSV.open("event_attendees.csv",headers: true,header_converters: :symbol)
  max_hour = 0
  max_count = 0
  hash = Hash.new
  file.each do |line|
    d = Time.strptime(line[:regdate].split(" ")[1].strip(),'%H:%M')
    x = d.hour.to_i
    if hash[x].nil?
      hash[x] = 1
    else
      hash[x]+=1
    end
    if hash[x]>max_count
      max_hour = x 
      max_count = hash[x].to_i
    end
  end
  return max_hour
end
def file_generation(id,form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks#{id}.html"
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end
puts "Eventmanager Initialized!"
file = CSV.open("event_attendees.csv",headers: true,header_converters: :symbol)
template_letter = File.read("template.erb")
template_erb = ERB.new template_letter
file.each do |line|
  id = line[0]
  name = line[:first_name]
  zipcode = clean_zipcode(line[:zipcode])
  legislators = display_legislators(zipcode)
  form_letter = template_erb.result(binding)
  file_generation(id,form_letter)
end