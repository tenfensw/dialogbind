#!/usr/bin/env ruby
# DialogBind - a simple library wrapping around message box displaying
# tools on Linux (xmessage and zenity) and macOS
#
# Copyright (C) Tim K 2018-2019 <timprogrammer@rambler.ru>.
# Licensed under MIT License.

require 'fiddle/import'

$dialogbind_macos_script_cmd = ''
$dialogbind_version = '0.9.2.1'

# Function used internally in DialogBind to run Zenity from Ruby code. Please do not use this function directly as its API and behaviour might change in any release.
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

# Internal module binding Win32 API MessageBox to Ruby. While it can be used directly, it is not recommended to do so to maintain your app's portability.
module Win32NativeBindings
	# based on https://gist.github.com/Youka/3ebbdfd03454afa7d0c4
	if $dialogbind_dialog_backend == 'win32' then
		extend Fiddle::Importer

		dlload 'user32'
		dlload 'winmm'
		typealias 'HANDLE', 'void*'
		typealias 'HWND', 'HANDLE'
		typealias 'LPCSTR', 'const char*'
		typealias 'UINT', 'unsigned int'
		typealias 'BOOL', 'int'
		typealias 'HMODULE', 'void*'
		typealias 'DWORD', 'unsigned long'

		extern 'int MessageBox(HWND, LPCSTR, LPCSTR, UINT)'
		extern 'BOOL PlaySound(LPCTSTR, HMODULE, DWORD)'
	else
		def MessageBox(arg1, arg2, arg3, arg4)
			return
		end

		def PlaySound(arg1, arg2, arg3)
			return 1
		end
	end
end

# Function used internally in DialogBind to run Win32 MessageBoxA from Ruby code. Please do not use this function directly as its API and behaviour might change in any release.
def win32_msgbox(text, title='DialogBind', buttons=0)
	return Win32NativeBindings::MessageBox(nil, text, title, buttons)
end

# Function used internally in DialogBind to run XMessage from Ruby code. Please do not use this function directly as its API and behaviour might change in any release.
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

# Function used internally in DialogBind to run AppleScript ``display dialog`` from Ruby code. Please do not use this function directly as its API and behaviour might change in any release.
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

$dialogbind_available_backends = [ 'xmessage', 'zenity', 'macos', 'win32' ]
$dialogbind_dialog_backend = 'xmessage'

if system('command -v zenity > /dev/null 2>&1') then
	$dialogbind_dialog_backend = 'zenity'
elsif ENV.keys.include?('OS') && ENV['OS'] == 'Windows_NT' then
	$dialogbind_dialog_backend = 'win32'
elsif `uname`.gsub("\n", "") == 'Darwin' then
	$dialogbind_dialog_backend = 'macos'
end

if ENV.keys.include? 'DIALOGBIND_BACKEND' then
	$dialogbind_dialog_backend = ENV['DIALOGBIND_BACKEND']
end
if $dialogbind_available_backends.include?($dialogbind_dialog_backend) == false then
	raise 'Dialog backend "' + $dialogbind_dialog_backend + '" is not available. Available frontends: ' + $dialogbind_available_backends.join(', ')
end

# Shows a simple message box (or information message box when using Zenity backend).
#
# @param text [String] the text that should be displayed in a message box
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [Boolean] true on success, false if something went wrong
def guiputs(text, title='DialogBind')
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage(text, { 'OK' => 0 })
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity({ 'info' => nil, 'title' => title, 'text' => text })
	elsif $dialogbind_dialog_backend == 'macos' then
		return macdialog(text)
	elsif $dialogbind_dialog_backend == 'win32' then
		win32_msgbox(text, title, 0)
		return true
	else
		puts title + ': ' + text
		return true
	end
	return false
end

# Shows a question message box with "Yes" and "No" buttons.
#
# @param text [String] the text that should be displayed in a message box
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [Boolean] true if the user presses yes, false if the user pressed no
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
	elsif $dialogbind_dialog_backend == 'win32' then
		retv_msgbox = win32_msgbox(text, title, 36)
		return (retv_msgbox == 6)
	else
		raise 'The selected backend does not support question message boxes.'
	end
	return false
end

# Shows an error message box with only single OK button.
#
# @param text [String] the text that should be displayed in a message box
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [Boolean] true on success, false if something went wrong
def guierror(text, title='DialogBind')
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage('ERROR. ' + text, { 'OK' => 0 })
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity('error' => nil, 'title' => title, 'text' => text)
	elsif $dialogbind_dialog_backend == 'macos' then
		return macdialog(text, [ 'OK' ], 'dialog', true)
	elsif $dialogbind_dialog_backend == 'win32' then
		return win32_msgbox(text, title, 16)
	else
		raise 'The selected backend does not support question message boxes.'
	end
	return false
end

# Shows either a buttonless message box with the specified text or a progress message box with the specified text. Does not work on Windows.
# This function is not async, just like all other functions, so you should actually start it in a seperate thread.
#
# @param text [String] the text that should be displayed in a message box
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [Boolean] true on success, false if something went wrong
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

# Shows a message box containing the license agreement that is stored in the specified file.
#
# @param file [String] the file that contains the licensing terms
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [Boolean] true if the user accepts the terms of the license agreement or false if not
def guilicense(file, title='DialogBind')
	if File.exists?(file) == false then
		guierror('File "' + file + '" does not exist.', title)
		return false
	end
	if $dialogbind_dialog_backend == 'xmessage' then
		return xmessage(file, { 'Accept' => 0, 'Decline' => 1 }, true)
	elsif $dialogbind_dialog_backend == 'zenity' then
		return zenity({ 'text-info' => nil, 'title' => title, 'filename' => file, 'checkbox' => 'I have read and accepted the terms of the license agreement.' })
	elsif $dialogbind_dialog_backend == 'macos' then
		macdialog('Right now, the license agreement will be shown in TextEdit. Close TextEdit using Command-Q to continue,', ['OK'])
		system('open -e "' + file.gsub('"', "\\\"") + '"')
		return guiyesno('Do you accept the terms of the license agreement?', title)
	elsif $dialogbind_dialog_backend == 'win32' then
		retv_msgbox = win32_msgbox("Do you accept the terms of the license agreement below?\n\n" + File.read(file), title, 36)
		return (retv_msgbox == 6)
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

# Shows either a message box with buttons matching the items specified in the array ``entries`` or a list message box.
#
# @param entries [Array] an array of strings that should be displayed as list in a message box. More than two items are currently not supported.
# @param text [String] the text that should be displayed in a message box
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [String] the selected string or nil on cancel
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
	else
		raise 'The selected backend does not support license message boxes.'
		return false
	end
	return nil
end

# DialogBindSystemSounds is a module providing default DialogBind sound IDs to functions like guisound.
module DialogBindSystemSounds
	None = 0
	Success = 1
	Error = 2
	Attention = 3
end

def nativesoundplay(sound_path)
	unix_cmd_optimized_path = sound_path.gsub('"', "\\\"")
	if $dialogbind_dialog_backend == 'win32' then
		Win32NativeBindings::PlaySound(sound_path, nil, SND_SYNC)
	elsif $dialogbind_dialog_backend == 'macos' then
		system('afplay "' + unix_cmd_optimized_path + '" > /dev/null 2>&1')
	else
		if system('command -v play > /dev/null 2>&1') then
			system('play "' + unix_cmd_optimized_path + '" > /dev/null 2>&1')
		elsif system('command -v paplay > /dev/null 2>&1') then
			system('paplay "' + unix_cmd_optimized_path + '" > /dev/null 2>&1')
		elsif system('command -v canberra-gtk-play > /dev/null 2>&1') then
			system('canberra-gtk-play -f "' + unix_cmd_optimized_path + '" > /dev/null 2>&1')
		elsif system('command -v mpv > /dev/null 2>&1') then
			system('mpv "' + unix_cmd_optimized_path + '" > /dev/null 2>&1')
		elsif system('command -v mplayer > /dev/null 2>&1') then
			system('mplayer "' + unix_cmd_optimized_path + '" > /dev/null 2>&1')
		else
			system('xdg-open "' + unix_cmd_optimized_path + '"')
		end
	end
end

def linuxsound(sound_v)
	sound_theme = '/usr/share/sounds/freedesktop/stereo'
	sound_theme_success = sound_theme + '/complete.oga'
	sound_theme_error = sound_theme + '/dialog-error.oga'
	sound_theme_attention = sound_theme + '/window-attention.oga'
	if File.directory?(sound_theme) == false then
		return
	end
	if sound_v == DialogBindSystemSounds::Success then
		nativesoundplay(sound_theme_success)
	elsif sound_v == DialogBindSystemSounds::Error then
		nativesoundplay(sound_theme_error)
	else
		nativesoundplay(sound_theme_attention)
	end
end

# Plays the default system sounds.
#
# @param sound_v [DialogBindSystemSounds] the sound to play. Available values are DialogBindSystemSounds::Success,
# DialogBindSystemSounds::Error and DialogBindSystemSounds::Attention. Specifying DialogBindSystemSounds::None will
# do nothing.
# @return [Object] nothing
def guisound(sound_v)
	if sound_v == DialogBindSystemSounds::None then
		return
	end
	if $dialogbind_dialog_backend != 'macos' && $dialogbind_dialog_backend != 'win32' then
		linuxsound(sound_v)
		return
	end
	constant_sound_success = '/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/burn complete.aif'
	constant_sound_error = '/System/Library/Sounds/Funk.aiff'
	constant_sound_attention = '/System/Library/PrivateFrameworks/FindMyDevic.framework/Versions/A/Resources/fmd_sound.aiff'
	if File.exists?(constant_sound_attention) == false then
		constant_sound_attention = constant_sound_success
	end
	if File.exists?(constant_sound_success) == false then
		constant_sound_success = constant_sound_error
	end
	if $dialogbind_dialog_backend == 'win32' then
		constant_sound_success = 'c:/Windows/Media/tada.wav'
		constant_sound_error = 'c:/Windows/Media/Windows Error.wav'
		if File.exists?(constant_sound_error) == false then
			constant_sound_error = 'c:/Windows/Media/chord.wav'
		end
		constant_sound_attention = 'c:/Windows/Media/chimes.wav'
	end
	if sound_v == DialogBindSystemSounds::Success then
		nativesoundplay(constant_sound_success)
	elsif sound_v == DialogBindSystemSounds::Error then
		nativesoundplay(constant_sound_error)
	else
		nativesoundplay(constant_sound_attention)
	end
end
