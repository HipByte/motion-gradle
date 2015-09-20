class Aidl
  def initialize(package, aidl_file_path)
    @package = package
    @aidl_file_path = File.expand_path(aidl_file_path)
  end

  def create_lib
    create_lib_structure
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
    io = File.new(File.join(path, 'src', 'main', 'AndroidManifest.xml'), "w")
    io.puts("<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\" package=\"#{@package}\"></manifest>")
    io.close
  end

  def create_gradle_build_file
    locals = {last_build_tools_version: last_build_tools_version}
    erb_template = generate_erb_template(File.expand_path("../aidl_build_gradle.erb", __FILE__), locals)
    io = File.new(File.join(path, 'build.gradle',), "w")
    io.puts(erb_template)
    io.close
  end

  def create_lib_structure
    aidl_file_dir = File.join(path, 'src', 'main', 'aidl', *@package.split('.'))
    FileUtils.mkdir_p(aidl_file_dir)
    FileUtils.cp(@aidl_file_path, aidl_file_dir)
  end

  def generate_erb_template(path, locals)
    template_path = File.expand_path(path, __FILE__)
    template = File.new(template_path).read
    ERB.new(template).result(OpenStruct.new(locals).instance_eval { binding })
  end

  def last_build_tools_version
    build_tools = File.join(ENV['RUBYMOTION_ANDROID_SDK'], 'build-tools')
    builds_tools_directories = Dir.glob(File.join(build_tools, '*')).select {|f| File.directory? f}
    File.basename(builds_tools_directories.last)
  end
end
