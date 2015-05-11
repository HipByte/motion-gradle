unless defined?(Motion::Project::Config)
  raise("This file must be required within a RubyMotion project Rakefile.")
end

if Motion::Project::App.template != :android
  raise("This file must be required within a RubyMotion Android project.")
end

module Motion::Project
  class Config
    variable :gradle

    def gradle(&block)
      @gradle ||= Motion::Project::Gradle.new(self)
      if block
        @gradle.instance_eval(&block)
      end
      @gradle
    end
  end

  class Gradle
    GRADLE_ROOT = 'vendor/Gradle'

    def initialize(config)
      @gradle_path = '/usr/bin/env gradle'
      @config = config
      @dependencies = []
      @repositories = []
      configure_project
    end

    def configure_project
      vendor_aars
      vendor_jars
    end

    def path=(path)
      @gradle_path = path
    end

    def dependency(name, options = {})
      if name.include?(':')
        @dependencies << name
      else
        App.info('[deprecated]', "dependency('name', options) syntax is deprecated please use a gradle config string, eg: dependency('com.joanzapata.pdfview:android-pdfview:1.0.+@aar') ")
        @dependencies << normalized_dependency(name, options)
      end
    end

    def repository(url, options = {})
      @repositories << url
    end

    def install!(update)
      generate_gradle_build_file
      system("#{gradle_command} --build-file #{gradle_build_file} generateDependencies")

      # this might be uneeded in the future
      # if RM does support .aar out of the box
      extract_aars
    end

    def android_repository
      android_repository = File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'extras', 'android', 'm2repository')
      unless exist = File.exist?(android_repository)
        App.info('[warning]', "To avoid issues you should install `Extras/Android Support Repository`. Open the gui to install it : #{android_gui_path}")
      end
      exist
    end

    def google_repository
      google_repository = File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'extras', 'google', 'm2repository')
      unless exist = File.exist?(google_repository)
        App.info('[warning]', "To avoid issues you should install `Extras/Google Repository`. Open the gui to install it : #{android_gui_path}")
      end
      exist
    end

    # Helpers
    def vendor_aars
      aars_dependendies = Dir[File.join(GRADLE_ROOT, 'aar/*')]
      aars_dependendies.each do |dependency|
        vendor_options = {:jar => File.join(dependency, 'classes.jar')}

        res = File.join(dependency, 'res')
        if File.exist?(res)
          vendor_options[:resources] = res
          vendor_options[:manifest] = File.join(dependency, 'AndroidManifest.xml')
        end

        native = File.join(dependency, 'jni')
        if File.exist?(native)
          archs = @config.archs.uniq.map do |arch|
            @config.armeabi_directory_name(arch)
          end
          libs = Dir[File.join(native, "{#{archs.join(',')}}", "*.so")]
          vendor_options[:native] = libs
        end

        @config.vendor_project(vendor_options)
      end
    end

    def vendor_jars
      jars = Dir[File.join(GRADLE_ROOT, 'dependencies/*.jar')]
      jars.each do |jar|
        @config.vendor_project(:jar => jar)
      end
    end

    def android_gui_path
      @android_gui_path ||= File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'tools', 'android')
    end

    def extract_aars
      aars = Dir[File.join(GRADLE_ROOT, "dependencies/**/*.aar")]
      aar_dir = File.join(GRADLE_ROOT, 'aar')
      FileUtils.mkdir_p(aar_dir)
      aars.each do |aar|
        filename = File.basename(aar, '.aar')
        system("unzip -o -qq #{aar} -d #{aar_dir}/#{filename}")
      end 
    end

    def generate_gradle_build_file
      template_path = File.expand_path("../gradle.erb", __FILE__)
      template = ERB.new(File.new(template_path).read, nil, "%")
      File.open(gradle_build_file, 'w') do |io|
        io.puts(template.result(binding))
      end
    end

    def gradle_build_file
      File.join(GRADLE_ROOT, 'build.gradle')
    end

    def gradle_command
      unless system("command -v #{@gradle_path} >/dev/null")
        $stderr.puts("[!] #{@gradle_path} command doesn’t exist. Verify your gradle installation. Or set a different one with `app.gradle.path=(path)`")
        exit(1)
      end

      if ENV['MOTION_GRADLE_DEBUG']
        "#{@gradle_path} --info"
      else
        "#{@gradle_path}"
      end
    end

    def normalized_dependency(name, options)
      {
        name: name,
        version: options.fetch(:version, '+'),
        artifact: options.fetch(:artifact, name),
        extension: options.fetch(:extension, "jar"),
      }
    end

    def inspect
      @dependencies.map do |dependency|
        "#{dependency[:name]} - #{dependency[:artifact]} (#{dependency[:version]})"
      end.inspect
    end
  end
end

namespace :gradle do
  desc "Download and build dependencies"
  task :install do
    root = Motion::Project::Gradle::GRADLE_ROOT
    FileUtils.mkdir_p(root)
    rm_rf(File.join(root, 'dependencies'))
    rm_rf(File.join(root, 'aar'))
    dependencies = App.config.gradle
    dependencies.install!(true)
  end
end

namespace :clean do
  task :all do
    root = Motion::Project::Gradle::GRADLE_ROOT
    if File.exist?(root)
      App.info('Delete', root)
      rm_rf(root)
    end
  end
end
