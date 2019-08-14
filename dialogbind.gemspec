require 'rubygems'
require_relative 'lib/dialogbind.rb'

Gem::Specification.new do |gemdesc|
	gemdesc.name = 'dialogbind'
	gemdesc.version = $dialogbind_version
	gemdesc.author = [ 'Tim K' ]
	gemdesc.email = [ 'timprogrammer@rambler.ru' ]
	gemdesc.date = '2019-08-14'
	gemdesc.homepage = 'https://github.com/timkoi/dialogbind'
	gemdesc.summary = 'DialogBind provides a portable Ruby API for creating simple message box-based interfaces that work on Linux, macOS and Windows.'
	gemdesc.description = 'DialogBind is a library providing a cross-platform API for creating dialog and message boxes from Ruby code. Docs are available here: https://www.rubydoc.info/gems/dialogbind/'
	gemdesc.files = [ 'lib/dialogbind.rb' ]
	gemdesc.required_ruby_version = Gem::Requirement.new('>= 2.2.0')
	gemdesc.require_paths = [ 'lib' ]
	gemdesc.licenses = [ 'MIT' ]
end
