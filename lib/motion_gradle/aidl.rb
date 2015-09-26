module MotionGradle
  class Aidl
    def initialize(package, aidl_file_path)
      @package = package
      @aidl_file_path = File.expand_path(aidl_file_path)
    end

    def create_lib
      create_structure
      create_gradle_build_file
      create_manifest
    end

    def name
      @name ||= File.basename(@aidl_file_path, '.aidl').downcase
    end

    def path
      @path ||= File.join(Motion::Project::Gradle::GRADLE_ROOT, name)
    end

    protected

    def create_manifest
      template = MotionGradle::Template.new('android_manifest.xml')
      template.destination = File.join(path, 'src', 'main', 'AndroidManifest.xml')
      template.write({ package: @package })
    end

    def create_gradle_build_file
      template = MotionGradle::Template.new('aidl_build.gradle')
      template.destination = File.join(path, 'build.gradle')
      template.write({ last_build_tools_version: last_build_tools_version })
    end

    def create_structure
      aidl_file_dir = File.join(path, 'src', 'main', 'aidl', *@package.split('.'))
      FileUtils.mkdir_p(aidl_file_dir)
      FileUtils.cp(@aidl_file_path, aidl_file_dir)
    end

    def last_build_tools_version
      build_tools = File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'build-tools')
      glob_pattern = File.join(build_tools, '*')
      builds_tools_directories = Dir.glob(glob_pattern).select do |file|
        File.directory?(file)
      end
      File.basename(builds_tools_directories.last)
    end
  end
end
