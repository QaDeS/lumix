spec = Gem::Specification.new do |s|
  s.name = 'lumix'
  s.version = '0.0.2'
  s.platform = 'java'
  s.has_rdoc = false
  s.summary = "A concordancer for corpus-based linuistic research."
  s.description = "Lumix helps you create and tag a corpus from raw texts, as well as search in it with a simple query language."
  s.author = "Michael Klaus"
  s.email = "Michael.Klaus@gmx.net"
  s.homepage = "http://github.org/QaDeS/lumix"
  s.files = %w(COPYING) + Dir["{bin,spec,lib}/**/*"]
  s.require_path = "lib"
  s.bindir = 'bin'
  s.executables << 'lumix'
  s.executables << 'lumix-gui'

  s.add_dependency 'ffi-icu'
  s.add_dependency 'msgpack-jruby'
  s.add_dependency 'htmlentities'
  s.add_dependency 'sequel'
  s.add_dependency 'savon'
  s.add_dependency 'curb'
  s.add_dependency 'jdbc-postgres'

  s.add_dependency 'sweet'
end
