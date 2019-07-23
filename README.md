# DialogBind
*Copyright (C) Tim K 2018-2019 <timprogrammer@rambler.ru>. Licensed under MIT License.*<br>
https://rubygems.org/gems/dialogbind

DialogBind is a library wrapping around message box displaying tools (zenity and xmessage) on Linux, macOS and Windows written in Ruby.

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

That's it! You can use it from your code, but it will only work on Linux, macOS, Windows and FreeBSD. Other platforms are not supported right now.

## Docs
Docs are available on RubyDoc: http://www.rubydoc.info/gems/dialogbind/


