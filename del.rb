require 'csv'
require 'open-uri'

csv_url = 'https://raw.githubusercontent.com/yussufacik/iana_jobs/main/DailyActivities.csv'
daily_activities = []

begin
  URI.open(csv_url) do |file|
    csv = CSV.new(file, headers: true, header_converters: :symbol, liberal_parsing: true)
    csv.each do |row|
      daily_activities << row.to_hash
    end
  end
rescue CSV::MalformedCSVError => e
  puts "Error reading CSV: #{e.message}"
end

csv_url = 'https://raw.githubusercontent.com/yussufacik/iana_jobs/main/Users.csv'
invalid_users_csv = []

URI.open(csv_url) do |file|
  csv = CSV.new(file, headers: true, header_converters: :symbol, liberal_parsing: true)
  csv.each do |row|
    invalid_users_csv << row.to_hash
  end
end

username_email_map = {}
invalid_users_csv.each do |user|
  username_email_map[user[:username]] = User.find_by email: user[:email]
end

not_found_users = []
errors = []
first_errors = []
second_errors = [] 
ActiveRecord::Base.transaction do
  daily_activities.each_with_index do |daily_activity, index|
    puts index
    employee = username_email_map[daily_activity[:username]]
    unless employee
      not_found_users << daily_activity
      next
    end
    expected_activity =  JSON.parse(daily_activity[:daily_activity_attributes].gsub("'", "\""))

    project = Project.find_by(name: expected_activity["project_name"])

    existing_daily_activity = DailyActivity.find_by(date: daily_activity[:date], user_id: employee.id)


    new_daily_activity = DailyActivity.new(daily_activity.except(:daily_activity_attributes, :username, :time_break).merge(user_id: employee.id, time_break: daily_activity[:time_break] || "00:00"))

attributes_to_compare = DailyActivity.attribute_names - %w[id created_at updated_at]

existing_attrs = existing_daily_activity.attributes.slice(*attributes_to_compare)
new_attrs = new_daily_activity.attributes.slice(*attributes_to_compare)

    if new_daily_activity&.errors&.any? || existing_daily_activity&.errors&.any?
      puts "error"
      puts new_daily_activity.errors.to_json
      puts "existing"
      puts existing_daily_activity.errors.to_json
      errors << daily_activity
      next
    end

    unless new_daily_activity&.save
      puts "second error"
      puts new_daily_activity.errors.to_json
      first_errors << daily_activity
      next
    end
    puts "herreeeee"
    puts new_daily_activity.id

    new_daily_project_activity = DailyProjectActivity.create!(
      {
        project_id: project.id,
        time_spent: expected_activity['time_spent'],
        daily_activity_id: new_daily_activity.id
      }
    )
    unless new_daily_project_activity
      second_errors << daily_activity
    end

  end

  puts "num of errors: #{errors.count}"
  puts "num of first errors: #{first_errors.count}"
  puts "num of second errors: #{second_errors.count}"

  raise ActiveRecord::Rollback if errors.any? || second_errors.any? || first_errors = []
end


not_found_users = []
errors = []
first_errors = []
second_errors = [] 
daily_activities.each_with_index do |daily_activity, index|
  puts index
  employee = username_email_map[daily_activity[:username]]
  unless employee
    not_found_users << daily_activity
    next
  end
  expected_activity =  JSON.parse(daily_activity[:daily_activity_attributes].gsub("'", "\""))

  project = Project.find_by(name: expected_activity["project_name"])

  existing_daily_activity = DailyActivity.find_by(date: daily_activity[:date], user_id: employee.id)

  new_daily_activity = DailyActivity.new(daily_activity.except(:daily_activity_attributes, :username, :time_break).merge(user_id: employee.id, time_break: daily_activity[:time_break] || "00:00"))

  if new_daily_activity&.errors&.any? || existing_daily_activity&.errors&.any?
    errors << daily_activity
    next
  end

end

  puts "num of errors: #{errors.count}"
  puts "num of first errors: #{first_errors.count}"
  puts "num of second errors: #{second_errors.count}"



not_found_users = []
errors = []
first_errors = []
second_errors = [] 
counts = [] 
ActiveRecord::Base.transaction do
  daily_activities.each_with_index do |daily_activity, index|
    puts index
    employee = username_email_map[daily_activity[:username]]
    unless employee
      not_found_users << daily_activity
      next
    end
    expected_activity =  JSON.parse(daily_activity[:daily_activity_attributes].gsub("'", "\""))

    project = Project.find_by(name: expected_activity["project_name"])

    existing_daily_activity = DailyActivity.find_by(date: daily_activity[:date], user_id: employee.id)


    new_daily_activity = DailyActivity.new(daily_activity.except(:daily_activity_attributes, :username, :time_break).merge(user_id: employee.id, time_break: daily_activity[:time_break] || "00:00"))

    attributes_to_compare = DailyActivity.attribute_names - %w[id created_at updated_at]

    existing_attrs = existing_daily_activity.attributes.slice(*attributes_to_compare)
    new_attrs = new_daily_activity.attributes.slice(*attributes_to_compare)
    unless new_attrs == existing_attrs
    errors << daily_activity
    end

counts <<  DailyProjectActivity.where(daily_activity_id: existing_daily_activity.id).count
end


# could you write a method which reads a csv from github url and gives it to me
# as an array
# csv_url = 'https://raw.githubusercontent.com/yussufacik/iana_jobs/main/DailyActivities.csv'
# daily_activities = []
# a
