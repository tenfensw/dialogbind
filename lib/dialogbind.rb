#!/usr/bin/env ruby
# DialogBind - a simple library wrapping around message box displaying
# tools on Linux (zenity and kdialog), macOS and Windows
#
# Copyright (C) Tim K 2018-2019 <timprogrammer@rambler.ru>.
# Licensed under MIT License.

require 'fiddle/import'

$dialogbind_macos_script_cmd = ''
$dialogbind_version = '0.9.5'

# @!visibility private
def zenity(arg)
	args_total = ''
	arg.keys.each do |key|
		key_o = key
		if key[-1] == '%' then
			key_o = key.gsub('%', '')
		end
		if arg[key] == nil then
			args_total += '--' + key_o
		elsif arg[key].instance_of? Array then
			arg[key].each do |nested_key|
				if nested_key != nil then
					args_total += "'" + nested_key.to_s.gsub("'", "") + "' "
				end
			end
		else
			args_total += '--' + key_o + "='" + arg[key].to_s.gsub("'", '"') + "'"
		end
		args_total += ' '
	end
	return system('zenity ' + args_total)
end

# @!visibility private
def kdialog(arg, redirect_output=false)
	args_total = ''
	arg.keys.each do |key|
		if arg[key].instance_of? Array then
			args_total += '--' + key + ' '
			arg[key].each do |instance_item|
				args_total += "'" + instance_item.to_s.gsub("'", '"') + "' "
			end
		elsif arg[key] != nil then
			args_total += '--' + key + " '" + arg[key].to_s.gsub("'", '"') + "' "
		else
			args_total += key
		end
	end
	if redirect_output then
		args_total += ' > /tmp/kdialog.sock 2>/dev/null'
	end
	return system('kdialog ' + args_total)
end

# @!visibility private
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

# @!visibility private
def macopen(text, ftype=[], folder=false)
	text_fixed = text.gsub("!", "").gsub("'", '').gsub('"', '').gsub('$', '')
	type = 'file'
	if folder then
		type = 'folder'
	end
	cmd = "osascript -e 'tell app \"System Events\" to choose " + type + ' with prompt "' + text_fixed + "\""
	if ftype.length > 0 then
		cmd += ' of type { '
		ftype.each do |extension|
			extension_real = extension.downcase
			if extension_real.include? '.' then
				extension_real = extension_real.split('.')[-1]
			end
			cmd += '"' + extension_real + '", '
		end
		cmd += '"*" }'
	end
	cmd += "'"
	cmd_output = `#{cmd} | cut -d ' ' -f2- | sed 's+:+/+g'`
	cmd_output.gsub!("\n", "")
	cmd_output = '/Volumes/' + cmd_output.clone
	if cmd_output == '/Volumes/' then
		return ''
	end
	return cmd_output
end

# @!visibility private
def macselect(items, text)
	cmd = 'osascript -e \'tell app "System Events" to choose from list ' + items.to_s.gsub('[', '{').gsub(']', '}').gsub("'", '')
	cmd += ' with prompt "' + text.to_s + '"\''
	cmd_output = `#{cmd}`.gsub("\n", "")
	if cmd_output == 'false' then
		return nil
	end
	return cmd_output
end

# @!visibility private
def macentry(text)
	cmd = "osascript -e 'display dialog \"" + text.gsub('"', '').gsub("'", '').gsub('!', '') + "\" default answer \"\" with icon note' | cut -d ':' -f3-"
	return `#{cmd}`.gsub("\n", "")
end

$dialogbind_available_backends = [ 'cli', 'zenity', 'kdialog', 'macos', 'win32' ]
$dialogbind_dialog_backend = 'cli'

if system('command -v kdialog > /dev/null 2>&1') && ENV.keys.include?('KDE_SESSION_VERSION') then
	$dialogbind_dialog_backend = 'kdialog'
elsif system('command -v zenity > /dev/null 2>&1') then
	$dialogbind_dialog_backend = 'zenity'
elsif ENV.keys.include?('OS') && ENV['OS'] == 'Windows_NT' then
	$dialogbind_dialog_backend = 'win32'
	require 'win32ole'
elsif `uname`.gsub("\n", "") == 'Darwin' then
	$dialogbind_dialog_backend = 'macos'
end

if ENV.keys.include? 'DIALOGBIND_BACKEND' then
	$dialogbind_dialog_backend = ENV['DIALOGBIND_BACKEND']
end
if $dialogbind_available_backends.include?($dialogbind_dialog_backend) == false then
	raise 'Dialog backend "' + $dialogbind_dialog_backend + '" is not available. Available frontends: ' + $dialogbind_available_backends.join(', ')
end

# @!visibility private
module Win32NativeBindings
	# based on https://gist.github.com/Youka/3ebbdfd03454afa7d0c4
	if $dialogbind_dialog_backend == 'win32' then
		extend Fiddle::Importer

		dlload 'user32'
		typealias 'HANDLE', 'void*'
		typealias 'HWND', 'HANDLE'
		typealias 'LPCSTR', 'const char*'
		typealias 'UINT', 'unsigned int'

		extern 'int MessageBox(HWND, LPCSTR, LPCSTR, UINT)'
	else
		def MessageBox(arg1, arg2, arg3, arg4)
			return
		end
	end
end

if $dialogbind_dialog_backend == 'win32' then
	# @!visibility private
	def win32_msgbox(text, title='DialogBind', buttons=0)
		return Win32NativeBindings.MessageBox(nil, text, title, buttons)
	end

	# @!visibility private
	def win32_activexplay(path)
		player = WIN32OLE.new('WMPlayer.OCX')
		player.OpenPlayer(sound_path)
	end

	# @!visibility private
	def win32_generatevbs(write_out)
		tmpfile_loc = ENV['TEMP'].gsub("\\", "/") + '/dialogbind_vbs_ibox' + rand(9999).to_s + '.vbs'
		if File.exists? tmpfile_loc then
			File.delete(tmpfile_loc)
		end
		File.write(tmpfile_loc, write_out)
		tmpfile_loc_w = tmpfile_loc.gsub('/', "\\")
		cmd_out = `cscript //Nologo "#{tmpfile_loc_w}"`.gsub("\r\n", "\n").gsub("\n", "")
		File.delete(tmpfile_loc)
		return cmd_out
	end

	# @!visibility private
	def win32_vbinputbox(text)
		write_out = 'a = inputbox("' + text.gsub('"', '').gsub("\r\n", "\n").gsub("\n", "\" + chr(13) + _ \n \"") + '")'
		write_out += "\r\nWScript.Echo a"
		return win32_generatevbs(write_out)
	end

	# @!visibility private
	def win32_activexopen(filters, title)
		filters_str = ''
		filters.each do |filter_pattern|
			to_append = 'Files matching pattern ' + filter_pattern + '|' + filter_pattern
			if filters_str == '' then
				filters_str = to_append
			else
				filters_str += '|' + to_append
			end
		end
		generated_vbs = "fso=CreateObject(\"UserAccounts.CommonDialog\")\r\nfso.Filter=\"" + filters_str + "\"\r\n"
		generated_vbs += "fso.FilterIndex=" + filters.length.to_s + "\r\nif fso.showOpen then\r\nWScript.Echo fso.fileName\r\nend if"
		return win32_generatevbs(generated_vbs)
	end

	# @!visibility private
	def win32_vbbrowseforfolder(title)
		generated_vbs = 'set ob=CreateObject("Shell.Application")'
		generated_vbs += "\r\nset fldr=ob.BrowseForFolder(0, \"" + title.gsub("\r\n", "\n").gsub("\n", "").gsub('"', "") + '", 0, "C:")'
		generated_vbs += "\r\nif not fldr is Nothing then"
		generated_vbs += "\r\nWScript.Echo fldr.Self.Path\r\nend if"
		return win32_generatevbs(generated_vbs)
	end
else
	# @!visibility private
	def win32_activexopen(filters, title)
		return ''
	end

	# @!visibility private
	def win32_vbbrowseforfolder(title)
		return ''
	end

	# @!visibility private
	def win32_msgbox(text, title='DialogBind', buttons=0)
		return -1
	end

	# @!visibility private
	def win32_activexplay(path)
		return
	end

	# @!visibility private
	def win32_vbinputbox(text)
		return ''
	end
end

# Shows a simple message box (or information message box when using Zenity backend).
#
# @param text [String] the text that should be displayed in a message box
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [Boolean] true on success, false if something went wrong
def guiputs(text, title='DialogBind')
	if $dialogbind_dialog_backend == 'zenity' then
		return zenity({ 'info' => nil, 'title' => title, 'text' => text })
	elsif $dialogbind_dialog_backend == 'macos' then
		return macdialog(text)
	elsif $dialogbind_dialog_backend == 'kdialog' then
		return kdialog({ 'title' => title, 'msgbox' => text })
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
	if $dialogbind_dialog_backend == 'zenity' then
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
	elsif $dialogbind_dialog_backend == 'kdialog' then
		return kdialog({ 'title' => title, 'yesno' => text })
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
	if $dialogbind_dialog_backend == 'zenity' then
		return zenity('error' => nil, 'title' => title, 'text' => text)
	elsif $dialogbind_dialog_backend == 'macos' then
		return macdialog(text, [ 'OK' ], 'dialog', true)
	elsif $dialogbind_dialog_backend == 'kdialog' then
		return kdialog({ 'title' => title, 'error' => text })
	elsif $dialogbind_dialog_backend == 'win32' then
		return win32_msgbox(text, title, 16)
	else
		raise 'The selected backend does not support question message boxes.'
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
	if $dialogbind_dialog_backend == 'zenity' then
		return zenity({ 'text-info' => nil, 'title' => title, 'filename' => file, 'checkbox' => 'I have read and accepted the terms of the license agreement.' })
	elsif $dialogbind_dialog_backend == 'macos' then
		macdialog('Right now, the license agreement will be shown in TextEdit. Close TextEdit using Command-Q to continue,', ['OK'])
		system('open -e "' + file.gsub('"', "\\\"") + '"')
		return guiyesno('Do you accept the terms of the license agreement?', title)
	elsif $dialogbind_dialog_backend == 'win32' then
		retv_msgbox = win32_msgbox("Do you accept the terms of the license agreement below?\n\n" + File.read(file), title, 36)
		return (retv_msgbox == 6)
	elsif $dialogbind_dialog_backend == 'kdialog' then
		kdialog({ 'textbox' => file, 'title' => title })
		if kdialog({ 'yesno' => 'Do you accept the terms of the license agreement?', 'title' => title }) then
			return true
		end
		return false
	else
		raise 'The selected backend does not support license message boxes.'
		return false
	end
	return false
end

# @!visibility private
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
# @param entries [Array] an array of strings that should be displayed as list in a message box.
# @param text [String] the text that should be displayed in a message box
# @param title [String] an optional parameter specifying the title of the message box. Ignored on macOS.
# @return [String] the selected string or nil on cancel
def guiselect(entries, text='Choose one of the items below:', title='DialogBind')
	if $dialogbind_dialog_backend == 'zenity' then
		array_of_items = []
		item_count_zenity = 0
		entries.each do |item|
			array_of_items.push(item_count_zenity)
			array_of_items.push(item)
			item_count_zenity += 1
		end
		if zenity({'list' => nil, 'radiolist' => nil, 'text' => text, 'print-column' => 'ALL', 'column' => '#', 'column%' => 'Items', '' => array_of_items, ' > /tmp/zenity.sock 2>/dev/null' => nil }) then
			return File.read('/tmp/zenity.sock').gsub("\n", "")
		else
			return nil
		end
	elsif $dialogbind_dialog_backend == 'kdialog' then
		list_args = [ text ]
		item_count = 0
		entries.each do |list_item|
			list_args.push(item_count)
			list_args.push(list_item)
			list_args.push('-')
			item_count += 1
		end
		if kdialog({ 'title' => title, 'radiolist' => list_args,}, true) == false then
			return nil
		end
		item_index = File.read('/tmp/kdialog.sock').gsub("\n", "").to_i
		if item_index > entries.length then
			return ''
		end
		return entries[item_index].clone
	elsif $dialogbind_dialog_backend == 'macos' then
		if entries.include? 'false' then
			raise 'The list of items to present to the user cannot contain the words "true" or "false" without additional punctuation due to limitations of AppleScript that is called from Ruby on macOS to display dialogs.'
		end
		return macselect(entries, text)
	elsif $dialogbind_dialog_backend == 'win32' then
		combined_msg = text.clone
		count = 0
		entries.each do |entry_item|
			combined_msg += "\r\n" + count.to_s + '. ' + entry_item.to_s
			count += 1
		end
		combined_msg += "\r\n" + " (To select one of the items above, enter the matching number before the dot)"
		entered_id = win32_vbinputbox(combined_msg).to_i
		if entered_id > entries.length then
			return ''
		end
		return entries[entered_id].clone
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

# @!visibility private
def nativesoundplay(sound_path)
	unix_cmd_optimized_path = sound_path.gsub('"', "\\\"")
	if $dialogbind_dialog_backend == 'win32' then
		win32_activexplay(sound_path)
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

# @!visibility private
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

# @!visibility private
def zenityfilter(filter)
	filter_out = []
	filter.each do |filter_item|
		filter_out.append('--file-filter=' + filter_item)
	end
	return filter_out
end

# Shows system-native file selection dialog. Currently does not work on Windows.
#
# @param filter [Array] an array of file patterns. Example: [ '*.rb', 'markdown-doc-toprocess*.md' ]
# @param title [String] an optional parameter specifying the title of the dialog box.
# @return [String] either an empty string (if the user cancels the dialog) or the native path to the file.
def guifileselect(filter=[], title='DialogBind')
	if $dialogbind_dialog_backend == 'macos' then
		return macopen(title, filter, false)
	elsif $dialogbind_dialog_backend == 'kdialog' then
		if kdialog({ 'title' => title, 'getopenfilename' => [] }, true) == false then
			return ''
		end
		return File.read('/tmp/kdialog.sock').gsub("\n", "")
	elsif $dialogbind_dialog_backend == 'zenity' then
		zenity({ 'title' => title, 'file-selection' => nil, '%' => zenityfilter(filter), ' > /tmp/zenity.sock 2>/dev/null' => nil })
		return File.read('/tmp/zenity.sock').gsub("\n", "")
	else
		raise 'The selected backend does not support file selection dialog boxes.'
		return ''
	end
	return ''
end

# Shows system-native directory selection dialog.
#
# @param title [String] an optional parameter specifying the title of the dialog box.
# @return [String] either an empty string (if the user cancels the dialog) or the native path to the file.
def guidirectoryselect(title='DialogBind')
	if $dialogbind_dialog_backend == 'macos' then
		return macopen(title, [], true)
	elsif $dialogbind_dialog_backend == 'kdialog' then
		if kdialog({ 'title' => title, 'getexistingdirectory' => [] }, true) == false then
			return ''
		end
		return File.read('/tmp/kdialog.sock').gsub("\n", "")
	elsif $dialogbind_dialog_backend == 'zenity' then
		zenity({ 'title' => title, 'file-selection' => nil, 'directory' => nil, ' > /tmp/zenity.sock 2>/dev/null' => nil })
		return File.read('/tmp/zenity.sock').gsub("\n", "")
	elsif $dialogbind_dialog_backend == 'win32' then
		return win32_vbbrowseforfolder(title).gsub("\\", '/')
	else
		raise 'The selected backend does not support directory selection dialog boxes.'
	end
	return ''
end

# Shows an input box with the specified text.
#
# @param text [String] the text that should be displayed in an input box
# @param title [String] an optional parameter specifying the title of the input box. Ignored on macOS and Windows.
# @return [String] the string that the user has typed in
def guigets(text='Type something:', title='DialogBind')
	if $dialogbind_dialog_backend == 'macos' then
		return macentry(text)
	elsif $dialogbind_dialog_backend == 'kdialog' then
		kdialog({ 'title' => title, 'inputbox' => [ text, '' ] }, true)
		return File.read('/tmp/kdialog.sock').gsub("\n", "")
	elsif $dialogbind_dialog_backend == 'zenity' then
		zenity({ 'title' => title, 'entry' => nil, 'text' => text, ' > /tmp/zenity.sock 2>/dev/null' => nil })
		return File.read('/tmp/zenity.sock').gsub("\n", "")
	elsif $dialogbind_dialog_backend == 'win32' then
		return win32_vbinputbox(text)
	else
		raise 'The selected backend does not support input boxes.'
		return ''
	end
	return ''
end
