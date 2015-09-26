# This is just so that the source file can be loaded.
module ::Motion; module Project; class Config
  def self.variable(*); end
end; end; end

require 'date'
$:.unshift File.expand_path('../lib', __FILE__)
require 'motion_gradle/version'

Gem::Specification.new do |spec|
  spec.name        = 'motion-gradle'
  spec.version     = MotionGradle::VERSION
  spec.date        = Date.today
  spec.summary     = 'Gradle integration for RubyMotion Android projects'
  spec.description = 'motion-gradle allows RubyMotion Android projects to have access to the Gradle dependency manager.'
  spec.author      = 'Joffrey Jaffeux'
  spec.email       = 'j.jaffeux@gmail.com'
  spec.homepage    = 'http://www.rubymotion.com'
  spec.license     = 'MIT'
  spec.files       = Dir.glob('lib/**/*.{erb,rb}') << 'README.md' << 'LICENSE'
  spec.add_development_dependency 'rubocop'
end
