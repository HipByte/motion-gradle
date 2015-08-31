class Aidl
  def initialize(package, aidl_file_path)
    @package = package
    @aidl_file_path = File.expand_path(aidl_file_path)
    @root = File.join(Motion::Project::Gradle::GRADLE_ROOT, name)
  end

  def name
    extname = File.extname(@aidl_file_path)
    File.basename(@aidl_file_path, extname).downcase
  end

  def create_structure
    create_aidl_file
    create_build_file
    create_manifest
  end

  protected

  def create_manifest
    io = File.new(File.join(@root, 'src', 'main', 'AndroidManifest.xml'), "w")
    io.puts("<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\" package=\"#{@package}\"></manifest>")
    io.close
  end

  def create_build_file
    build_tools = File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'build-tools')
    builds_tools_directories = Dir.glob(File.join(build_tools, '*')).select {|f| File.directory? f}
    build_tools_version = File.basename(builds_tools_directories.last)

    platforms = File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'platforms')
    platforms_directories = Dir.glob(File.join(platforms, '*')).select {|f| File.directory? f}
    sdk_version = File.basename(platforms_directories.last).gsub('android-', '')

    locals = {
      sdk_version: sdk_version,
      build_tools_version: build_tools_version
    }
    erb_template = generate_erb_template(File.expand_path("../aidl_build_gradle.erb", __FILE__), locals)

    io = File.new(File.join(@root, 'build.gradle',), "w")
    io.puts(erb_template)
    io.close
  end

  def create_aidl_file
    aidl_file_dir = File.join(@root, 'src', 'main', 'aidl', *@package.split('.'))
    FileUtils.mkdir_p(aidl_file_dir)
    FileUtils.cp(@aidl_file_path, aidl_file_dir)
  end

  def generate_erb_template(path, locals)
    template_path = File.expand_path(path, __FILE__)
    template = File.new(template_path).read
    ERB.new(template).result(OpenStruct.new(locals).instance_eval { binding })
  end

end
