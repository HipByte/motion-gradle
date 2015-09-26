unless defined?(Motion::Project::Config)
  fail('This file must be required within a RubyMotion project Rakefile.')
end

if Motion::Project::App.template != :android
  fail('This file must be required within a RubyMotion Android project.')
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
    attr_reader :dependencies
    attr_reader :libraries
    attr_reader :aidls

    def initialize(config)
      @gradle_path = '/usr/bin/env gradle'
      @config = config
      @classpaths = []
      @plugins = []
      @dependencies = []
      @repositories = []
      @aidl_files = []
      @libraries = []
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
        @dependencies << MotionGradle::LegacyDependency.new(name, options)
      end
    end

    def library(library_name, options = {})
      path = options.fetch(:path, library_name)
      unless Pathname.new(path).absolute?
        path = File.join('../..', path)
      end
      @libraries << { name: library_name, path: path }
    end

    def aidl(package, aidl_file_path)
      @aidl_files << MotionGradle::Aidl.new(package, aidl_file_path)
    end

    def classpath(classpath)
      @classpaths << classpath
    end

    def plugin(plugin)
      @plugins << plugin
    end

    def repository(url)
      @repositories << url
    end

    def install!
      vendor_aidl_files
      generate_settings_file
      generate_build_file
      system("#{gradle_command} --build-file #{build_file} generateDependencies")

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
    def vendor_aidl_files
      @aidl_files.each do |aidl_file|
        aidl_file.create_lib
        library(aidl_file.name, path: aidl_file.path)
      end
    end

    def vendor_aars
      aars_dependendies = Dir[File.join(GRADLE_ROOT, 'aar/*')]
      aars_dependendies.each do |dependency|
        main_jar = File.join(dependency, 'classes.jar')
        if File.exist?(main_jar)
          jar_path = File.join(dependency, "#{File.basename(dependency)}.jar")
          FileUtils.mv(main_jar, jar_path)
          vendor_options = { jar: jar_path }
        else
          next
        end

        # libs/*.jar may contain dependencies, let's vendor them
        Dir[File.join(dependency, 'libs/*.jar')].each do |internal_dependancy|
          @config.vendor_project(jar: internal_dependancy)
        end

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

          libs = Dir[File.join(native, "{#{archs.join(',')}}", '*.so')]
          if libs.count != archs.count
            App.info('[warning]', "Found only #{libs.count} lib(s) -> #{libs.join(',')} for #{archs.count} arch(s) : #{archs.join(',')}")
          end
          vendor_options[:native] = libs
        end

        @config.vendor_project(vendor_options)
      end
    end

    def vendor_jars
      jars = Dir[File.join(GRADLE_ROOT, 'dependencies/*.jar')]
      jars.each do |jar|
        @config.vendor_project(jar: jar)
      end
    end

    def android_gui_path
      @android_gui_path ||= File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'tools', 'android')
    end

    def extract_aars
      aars = Dir[File.join(GRADLE_ROOT, 'dependencies/**/*.aar')]
      aar_dir = File.join(GRADLE_ROOT, 'aar')
      FileUtils.mkdir_p(aar_dir)
      aars.each do |aar|
        filename = File.basename(aar, '.aar')
        system("/usr/bin/unzip -o -qq #{aar} -d #{File.join(aar_dir, filename)}")
      end
    end

    def generate_settings_file
      template = MotionGradle::Template.new('settings.gradle')
      template.destination = settings_file
      template.write({libraries: @libraries})
    end

    def generate_build_file
      template = MotionGradle::Template.new('build.gradle')
      template.destination = build_file
      template.write({
        classpaths: @classpaths,
        plugins: @plugins,
        libraries: @libraries,
        repositories: @repositories,
        dependencies: @dependencies,
        android_repository: android_repository,
        google_repository: google_repository
      })
    end

    def build_file
      File.join(GRADLE_ROOT, 'build.gradle')
    end

    def settings_file
      File.join(GRADLE_ROOT, 'settings.gradle')
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
  end
end

namespace :gradle do
  desc 'Download and build dependencies'
  task :install do
    root = Motion::Project::Gradle::GRADLE_ROOT
    FileUtils.mkdir_p(root)
    rm_rf(File.join(root, 'dependencies'))
    rm_rf(File.join(root, 'aar'))
    dependencies = App.config.gradle
    dependencies.install!
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
