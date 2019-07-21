#!/usr/bin/env ruby
# DialogBind - a simple library wrapping around message box displaying
# tools on Linux (xmessage and zenity) and macOS
#
# Copyright (C) Tim K 2018-2019 <timprogrammer@rambler.ru>.
# Licensed under MIT License.

$dialogbind_macos_script_cmd = ''

def zenity(arg)
	args_total = ''
	arg.keys.each do |key|
		if key[-1] == '%' then
			key = key.sub('%', '')
		end
		if arg[key] == nil then
			args_total += '--' + key
		elsif arg[key].instance_of? Array then
			arg[key].each do |nested_key|
				if nested_key != nil then
					args_total += "'" + nested_key.to_s.gsub("'", "") + "' "
				end
			end
		else
			args_total += '--' + key + "='" + arg[key].to_s.gsub("'", '"') + "'"
		end
		args_total += ' '
	end
	return system('zenity ' + args_total)
end

def xmessage(arg, buttons={ 'OK' => 0 }, file=false)
	build_cmd = 'xmessage -center -buttons "'
	first = true
	buttons.keys.each do |button|
		if first then
			first = false
		else
			build_cmd += ','
		end
		build_cmd += button.gsub('"', '') + ':' + buttons[button].to_s
	end
	build_cmd += '" '
	if file then
		build_cmd += '-file '
	end
	build_cmd += '"' + arg.gsub('"', "'").gsub('!', '') + '"'
	return system(build_cmd)
end

def macdialog(text, buttons=['OK'], type='dialog', error=false, dryrun=false)
	text_fixed = text.gsub("!", "").gsub("'", '').gsub('"', '').gsub('$', '')
	cmd = "osascript -e 'tell app \"System Events\" to display " + type + ' "' + text_fixed + '"'
	if type != 'notification' then
		cmd += ' buttons ' + buttons.to_s.gsub('[', '{').gsub(']', '}')
	else
		cmd += ' with title "' + File.basename($0) + '"'
	end
	if error then
		 cmd += ' with icon caution'
	end
	cmd += "'"
	$dialogbind_macos_script_cmd = cmd
	if dryrun == false then
		return system(cmd + ' > /dev/null')
	end
	return false
end

$dialogbind_available_backends = [ 'xmessage', 'zenity', 'macos' ]
$dialogbind_dialog_backend = 'xmessage'

if system('command -v zenity > /dev/null 2>&1') then
	$dialogbind_dialog_backend = 'zenity'
elsif `uname`.gsub("\n", "") == 'Darwin' then
	$dialogbind_dialog_backend = 'macos'
end

if ENV.keys.include? 'DIALOGBIND_BACKEND' then
	$dialogbind_dialog_backend = ENV['DIALOGBIND_BACKEND']
end
if $dialogbind_available_backends.include?($dialogbind_dialog_backend) == false then
	raise 'Dialog backend "' + $dialogbind_dialog_backend + '" is not available. Available frontends: ' + $dialogbind_available_backends.join(', ')
end

def guiputs(text, title='DialogBind')
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage(text, { 'OK' => 0 })
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity({ 'info' => nil, 'title' => title, 'text' => text })
	elsif $dialogbind_dialog_backend == 'macos' then
		return macdialog(text)
	else
		puts title + ': ' + text
		return true
	end
	return false
end

def guiyesno(text, title='DialogBind')
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage(text, { 'Yes' => 0, 'No' => 1})
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity('question' => nil, 'title' => title, 'text' => text)
	elsif $dialogbind_dialog_backend == 'macos' then
		macdialog(text, [ 'Yes', 'No' ], 'dialog', false, true)
		output = `#{$dialogbind_macos_script_cmd}`.gsub("\n", "")
		if output == nil || output.include?(':') == false then
			return false
		end
		if output.split(':')[1].downcase == 'yes' then
			return true
		end
	else
		raise 'The selected backend does not support question message boxes.'
	end
	return false
end

def guierror(text, title='DialogBind')
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage('ERROR. ' + text, { 'OK' => 0 })
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity('error' => nil, 'title' => title, 'text' => text)
	elsif $dialogbind_dialog_backend == 'macos' then
		return macdialog(text, [ 'OK' ], 'dialog', true)
	else
		raise 'The selected backend does not support question message boxes.'
	end
	return false
end

def guiprogress(text='Please wait...', title='DialogBind')
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage(text, { })
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity({ 'progress' => nil, 'title' => title, 'text' => text, 'no-cancel' => nil, 'percentage' => 2, 'pulsate' => nil })
	elsif $dialogbind_dialog_backend == 'macos' then
		return macdialog(text, [], 'notification', false)
	else
		raise 'The selected backend does not support progress message boxes.'
		return false
	end
	return false
end

def guilicense(file, title='DialogBind')
	if File.exists?(file) == false then
		guierror('File "' + file + '" does not exist.', title)
		return false
	end
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage(file, { 'Accept' => 0, 'Decline' => 1 }, true)
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity({ 'text-info' => nil, 'title' => title, 'filename' => file, 'checkbox' => 'I have read and accepted the terms of the license agreement.' })
	else
		raise 'The selected backend does not support license message boxes.'
		return false
	end
	return false
end

def entry2buttonshash(entries)
	hash = {}
	count = 0
	entries.each do |entry|
		hash[entry] = count
		count += 1
	end
	return hash
end

def guiselect(entries, text='Choose one of the items below:', title='DialogBind')
	if entries.length > 2 then
		raise 'More than 2 entries for guiselect are not supported by xmessage.'
	end
	if $dialogbind_dialog_backend == 'xmessage' then
		if xmessage(text, entry2buttonshash(entries)) then
			return entries[0]
		else
			return entries[1]
		end
	elsif $dialogbind_dialog_backend == 'zenity' then
		array_of_items = [0, entries[0], nil, nil]
		if entries.length > 1 then
			array_of_items[2] = 1
			array_of_items[3] = entries[1]
		end
		if zenity({'list' => nil, 'radiolist' => nil, 'text' => text, 'print-column' => 'ALL', 'column' => '#', 'column%' => 'Items', '' => array_of_items, ' > /tmp/zenity.sock 2>/dev/null' => nil }) then
			return File.read('/tmp/zenity.sock').gsub("\n", "")
		else
			return nil
		end
	elsif $dialogbind_dialog_backend == 'macos' then
		macdialog(text, entries, 'dialog', false, true)
		output = `#{$dialogbind_macos_script_cmd}`.gsub("\n", "")
		if output == nil || output.include?(':') == false then
			return nil
		end
		return output.split(':')[1]
	end
	return nil
end
