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
          dependency 'net.sf.ehcache:ehcache:2.9.0'
          dependency 'com.google.android.gms', :artifact => 'play-services', :version => '7.3.0', extension: 'aar'
          dependency 'com.joanzapata.pdfview:android-pdfview:1.0.+@aar'
        end
      end

      Rake::Task['gradle:install'].invoke
    end
  end

  it "creates the dependencies in tmp/Gradle/dependencies" do
    @ran_install ||= true
    (Pathname.new(@config.project_dir) + 'Gradle/dependencies').should.exist
  end

  it "extracts aars format dependencies in tmp/Gradle/aar" do
    @ran_install ||= true
    dir = (Pathname.new(@config.project_dir) + 'Gradle/aar')
    dir.should.exist
    Dir[File.join(dir, '*')].count.should == 2
  end

  it "provides a list of the dependencies on #inspect" do
    @ran_install ||= true
    @config.gradle.dependencies.count.should == 5
  end
end
