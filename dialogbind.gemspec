require 'rubygems'

Gem::Specification.new do |gemdesc|
	gemdesc.name = 'dialogbind'
	gemdesc.version = '0.9.1.1'
	gemdesc.author = [ 'Tim K' ]
	gemdesc.email = [ 'timprogrammer@rambler.ru' ]
	gemdesc.date = '2019-07-21'
	gemdesc.homepage = 'https://gitlab.com/timkoi/dialogbind'
	gemdesc.summary = 'DialogBind provides a Ruby API that wraps around Linux and macOS message box-generating tools. As of version 0.9.2, Windows is also (partially) supported. See https://gitlab.com/timkoi/dialogbind/blob/master/README.md for documentation.'
	gemdesc.files = [ 'lib/dialogbind.rb' ]
	gemdesc.required_ruby_version = Gem::Requirement.new('>= 2.0.0')
	gemdesc.require_paths = [ 'lib' ]
	gemdesc.licenses = [ 'MIT' ]
end
