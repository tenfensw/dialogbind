#!/usr/bin/env ruby
# Simple reminders app written in Ruby and DialogBind.
# 
# Copyright (C) Tim K 2018-2019. Licensed under MIT License.
# This file is a DialogBind example.

require 'dialogbind'
require 'time'

# Get the name of the reminder
notification_name = guigets('What should I remind you?')
if notification_name == '' || notification_name == nil then
	# If nil or empty, then exit
	guierror('You did not specify a valid name for a reminder. Exiting.')
	exit 1
end

# Get the time of the reminder
time_alert = guigets('When should I remind you? (type the time in the following format: HH:MM)')
if not time_alert.to_s.include? ':' then
	# If there is no :, then the time was not specified at all
	guierror('You did not specify a valid time. Exiting.')
	exit 2
elsif time_alert.to_s.include? ' ' then
	# If there is a space, then the time was specified in a wrong format
	guierror('Please specify the date in the following format next time: HH:MM. For example: 22:30. Exiting for now.')
	exit 3
end

# Convert our stringified time to Ruby's Time object
time_real = Time.parse(time_alert)
if time_real < Time.now then
	guierror('Late night/early morning appointments are not supported.')
	exit 3
end

# Tell the user that we will remind him about his appointment
guinotify('You will be notified about "' + notification_name + '" on ' + time_real.to_s, 'Reminder added')

while Time.now < time_real do
	sleep 0.01
end

guinotify('It\'s "' + notification_name + '" time.', 'Important!')
exit 0

exit 1
