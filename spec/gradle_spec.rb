require File.expand_path('../spec_helper', __FILE__)

module Motion; module Project;
  class Vendor
    attr_reader :opts
  end

  class Config
    attr_writer :project_dir
  end

  class Gradle
    GRADLE_ROOT = 'tmp/Gradle'
  end
end; end

describe "motion-gradle" do
  extend SpecHelper::TemporaryDirectory

  before do
    unless @ran_install
      teardown_temporary_directory
      setup_temporary_directory

      context = self

      @config = App.config
      @config.project_dir = temporary_directory.to_s
      @config.api_version = '22.0'
      @config.instance_eval do
        gradle do
          dependency 'com.mcxiaoke.volley', :artifact => 'library', :version => '1.0.10'
          dependency 'commons-cli'
          dependency 'ehcache', :version => '1.2.3'
        end
      end

      Rake::Task['gradle:install'].invoke
    end
  end

  it "creates the dependencies.jar in tmp/Gradle/build/libs" do
    @ran_install ||= true
    (Pathname.new(@config.project_dir) + 'Gradle/build/libs/dependencies.jar').should.exist
  end

  it "provides a list of the dependencies on #inspect" do
    @ran_install ||= true
    @config.gradle.inspect.should == [
      "com.mcxiaoke.volley - library (1.0.10)",
      "commons-cli - commons-cli (+)",
      "ehcache - ehcache (1.2.3)"
    ].inspect
  end
end
