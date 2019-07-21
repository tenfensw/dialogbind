# DialogBind
*Copyright (C) Tim K 2018-2019 <timprogrammer@rambler.ru>. Licensed under MIT License.*
DialogBind is a library wrapping around message box displaying tools (zenity and xmessage) on Linux and macOS written in Ruby.

## A simple example
```
require 'dialogbind'

if guiyesno('Would you like me to show you a random number?', 'Message') == false then
	guierror('You have selected no.')
else
	guiputs(rand(20).to_s, 'Your random number')
end
```
This tiny program in Ruby will show a question dialog with yes and no buttons, with title "Message" and text "Would you like me to show you a random number?". That dialog will return either true if yes was clicked, otherwise, it returns false. If false is returned, an error with text "You have selected no." pops up. Otherwise, a random number from 0 to 19 is generated and is displayed in an information message box with title "Your random number". 

## Installing
Install RubyGem:
```
sudo gem install dialogbind
```

And then include it in your Ruby code the following way:
```
require 'dialogbind'
```

That's it! You can use it from your code, but it will only work on Linux, macOS and FreeBSD. Other platforms are not supported right now.

## Basic usage
Currently, the following functions are available:
 - ``def guiputs(text, title='DialogBind')`` - shows a simple information message box with the specified text and title. Returns true if the dialog box was successfully shown or false if something went wrong.
 - ``def guierror(text, title='DialogBind')`` - shows an error message box with the specified text and title. Returns the same value as guiputs.
 - ``def guiselect(list, text, title='DialogBind')`` - shows a list message box with the specified items and text/title. If the user selects nothing, '' is returned. The selection is returned if something was actually selected. If something goes wrong, nil is returned. More than two list entries are currently not supported.
 - ``def guilicense(file, title='DialogBind')`` - shows a license message box, the contents of which will be read from the specified file. Returns false if the license agreement was denied, otherwise, true is returned. Does not work on macOS.
 - ``def guiprogress(text, title='DialogBind')`` - shows a progress message box. It would be nice if you've placed it in a seperate thread. Currently, it is buggy when used with zenity backend, so it is not recommended for use in production.

The backend to use is determined automatically, though you can always specify it manually by setting the ``DIALOGBIND_BACKEND`` variable. Currently, ``xmessage``, ``macos`` and ``zenity`` are the only backends that are supported.

## Notice
Please keep in mind that this library was made, because a simple portable message box-based GUI was needed for TXLin Installer and the core functionality was split into a seperate library at the last minute. The API, backends and platform support might change at any minute. It is not recommended that you use this library in large projects. You can safely use it in your automation tools or scripts, though.

