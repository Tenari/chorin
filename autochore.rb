#!/usr/bin/env ruby
require 'yaml'
require 'date'

FILENAME = '.data.yml'
File.write(FILENAME, YAML.dump({users: [],chores:[]})) unless File.exists?(FILENAME)
data = YAML.load_file(FILENAME)

def read_command(data)
  root = ARGV[0]
  object = ARGV[1]
  case root
  when 'new'
    if object == 'user'
      create_user(data)
    elsif object == 'chore'
      create_chore(data)
    end
  when 'list'
    if ['user', 'users'].include? object
      list_users(data)
    elsif ['chore', 'chores'].include? object
      list_chores(data)
    end
  when 'assign'
    assign_chore(data)
  when 'send'
    send_chores(data)
  when 'delete'
    if ['user', 'users'].include? object
      delete_objects(data, :users)
    elsif ['chore', 'chores'].include? object
      delete_objects(data, :chores)
    end
  when 'help'
    puts "
the main commands are: new list assign send delete help

  new user|chore
  new user -n name -e email
  new chore -n name -f frequency(4d) [-t tag -o owner_name -s start_date]

  list users|chores
  list chores open|ready

  assign chore_name user_name

  send

  delete users|chores
"
  end
end

def create_user(data)
  opt1 = ARGV[2]
  opt1_val = ARGV[3]
  opt2 = ARGV[4]
  opt2_val = ARGV[5]
  name = nil
  email = nil
  if opt1 == '-n' && opt2 == '-e'
    name = opt1_val
    email = opt2_val
  elsif opt2 == '-n' && opt1 == '-e'
    name = opt2_val
    email = opt1_val
  end
  if name && email
    user = {name: name, email: email}
    data[:users].push(user)
    File.write(FILENAME, YAML.dump(data))
    puts "added 1 user, new total users is #{data[:users].count}"
  end
end
def create_chore(data)
  # supports -t -n -f -o -s
  opts = {}
  ARGV.each_with_index do |arg, i|
    next unless i >= 2
    opts[:tag] = ARGV[i+1] if arg == '-t'
    opts[:name] = ARGV[i+1] if arg == '-n'
    if arg == '-f'
      opts[:freq] = parse_freq(ARGV[i+1])
      return puts "BAD FREQUENCY FORMAT" if opts[:freq] == 0
    end
    opts[:owner] = ARGV[i+1] if arg == '-o'
    opts[:start] = Date.parse(ARGV[i+1]) if arg == '-s'
  end
  if opts[:name] && opts[:freq]
    chore = opts
    chore[:start] ||= Date.today
    chore[:owner] ||= nil
    if chore[:owner] && !find_user(data, chore[:owner])
      puts "ERROR, owner flag does not match a name of an actual user. Please use one of these, moron:\n"
      return list_users(data)
    end
    chore[:owner] = find_user(data, chore[:owner])[:name] if chore[:owner]
    data[:chores].push(chore)
    File.write(FILENAME, YAML.dump(data))
    puts "added 1 chore, new total chores is #{data[:chores].count}"
  else
    puts "you need to at least pass -n and -f"
  end
end
def list_users(data)
  puts "NAME\t\tEMAIL"
  data[:users].each do |user|
    puts "#{user[:name]}\t\t#{user[:email]}"
  end
end
def list_chores(data)
  list = data[:chores]
  if ARGV[2] == 'open'
    list = list.select {|c| !c[:owner]}
  elsif ARGV[2] == 'ready' || ARGV[2] == 'assigned'
    list = list.select {|c| c[:owner]}
  end

  puts "NAME\t\t\t\tFREQ\t\tTAG\t\tOWNER"
  list.each do |o|
    taken = (o[:name].length % 8) -1
    tabs = case taken
    when 0
      "\t\t\t\t"
    when 1
      "\t\t\t"
    when 2
      "\t\t"
    when 3
      "\t"
    end
    puts "#{o[:name]}#{tabs}#{o[:freq]} days\t\t#{o[:tag]}\t\t#{o[:owner] || '--'}"
  end
end
def assign_chore(data)
  chore_name = ARGV[1]
  user_name = ARGV[2]
  chore = find_chore(data, chore_name)
  user = find_user(data, user_name)
  return puts "either user or chore name dont match nuthin... it goes chore_name user_name" if !chore || !user
  chore[:owner] = user[:name]
  File.write(FILENAME, YAML.dump(data))
  print_obj chore
end
def send_chores(data)
  subjects = ["Many hands make light work", "Pitter patter lets get at her", "If you do what you love, youll never work a day in your life", "Back to chorin", "Lets fuck this pig", "Its a great day for hay", "Give your balls a tug", "Sort yerself out"]
  env = YAML.load_file('.env')
  data[:users].each do |user|
    chores = data[:chores].select {|c| c[:owner] == user[:name]}
    next unless chores.count > 0
    
    today_message = "Today you gotta:\n"
    tomorrow_message = "\n\nTomorrow you gotta:\n"
    chores.each do |chore|
      today_message += "- #{chore[:name]}\n" if chore_today?(chore)
      tomorrow_message += "- #{chore[:name]}\n" if chore_tomorrow?(chore)
    end
    message = "#{today_message.length == 17 ? 'Nuthin doin fer now' : today_message}#{tomorrow_message.length > 22 ? tomorrow_message : ''}"
    puts message
`bash -c "curl --url 'smtps://smtp.gmail.com:465' --ssl-reqd --mail-from '#{env[:from]}' --mail-rcpt '#{user[:email]}' --user '#{env[:from]}:#{env[:pw]}' -T <(echo 'From: Auto Chorin <#{env[:from]}>\nTo: Menial Grunt <#{user[:email]}>\nSubject: #{subjects[rand(subjects.length)]}\nContent-Type: text/plain;\n\n#{message}')"`
  end

end
def delete_objects(data, key)
  delete_code = 'i know what im doing'
  puts "WARNING\n\nYou are about to permanently wipe ALL #{key}\n\nIf this is really what you wanna do... type: '#{delete_code}'"
  str = STDIN.gets.strip
  if str == delete_code
    data[key] = []
    File.write(FILENAME, YAML.dump(data))
    puts "new total #{key}: #{data[key].count}"
  else
    puts "you typed it wrong so I assume you didn't really wanna do that"
  end
end

# UTILITY functions
def find_object(data, name, key)
  data[key].find {|u| u[:name].downcase == name.downcase}
end
def find_chore(data, name)
  find_object(data, name, :chores)
end
def find_user(data, name)
  find_object(data, name, :users)
end
def parse_freq(str)
  parsed = str.match(/(\d+)([d|w|m|y])/)
  return 0 unless parsed
  number = parsed[1].to_i
  timeframe = case parsed[2]
  when 'd'
    1
  when 'w'
    7
  when 'm'
    30
  when 'y'
    365
  end
  return 0 unless number && timeframe
  return number * timeframe
end

def print_obj(obj)
  obj.each do |k,v|
    puts "#{k}\t=>\t#{v}"
  end
end
def chore_day?(chore, day)
  current = chore[:start]
  while current < day do
    current += chore[:freq]
  end

  day == current
end
def chore_today?(chore)
  chore_day? chore, Date.today
end
def chore_tomorrow?(chore)
  chore_day? chore, Date.today+1
end
# the actual thing that does the stuff
read_command(data)
