require File.expand_path('../spec_helper', __FILE__)

module Motion
  module Project
    class Vendor
      attr_reader :opts
    end

    class Config
      attr_writer :project_dir
    end

    class Gradle
      GRADLE_ROOT = 'tmp/Gradle'
    end
  end
end

describe 'motion-gradle' do
  extend SpecHelper::TemporaryDirectory

  before do
    unless @ran_install
      teardown_temporary_directory
      setup_temporary_directory

      @config = App.config
      @config.project_dir = temporary_directory.to_s
      @config.api_version = '22.0'
      @config.instance_eval do
        gradle do
          dependency 'com.mcxiaoke.volley', artifact: 'library',
                                            version: '1.0.10'
          dependency 'commons-cli'
          dependency 'net.sf.ehcache:ehcache:2.9.0'
          dependency 'com.google.android.gms', artifact: 'play-services',
                                               version: '7.3.0',
                                               extension: 'aar'
          dependency 'com.joanzapata.pdfview:android-pdfview:1.0.+@aar'
          dependency 'com.joanzapata.pdfview:android-pdfview:1.0.+@aar'

          aidl 'com.android.vending.billing', './spec/fixtures/IInAppBillingService.aidl'
        end
      end

      Rake::Task['gradle:install'].invoke
    end
  end

  it 'creates the dependencies in tmp/Gradle/dependencies' do
    @ran_install ||= true
    (Pathname.new(@config.project_dir) + 'Gradle/dependencies').should.exist
  end

  it 'extracts aars dependencies in tmp/Gradle/aar' do
    @ran_install ||= true
    dir = (Pathname.new(@config.project_dir) + 'Gradle/aar')
    dir.should.exist

    pdf_view = File.join(@config.project_dir, 'Gradle/aar/android-pdfview-1.0.4')
    File.exist?(pdf_view).should == true

    play_services = File.join(@config.project_dir, 'Gradle/aar/play-services-7.3.0')
    File.exist?(play_services).should == true
  end

  it 'generates the correct number of dependencies' do
    @ran_install ||= true
    @config.gradle.dependencies.count.should == 6
  end

  it 'generates the correct folder structure for aidl' do
    @ran_install ||= true
    gradle = File.join(@config.project_dir, 'Gradle/iinappbillingservice/build.gradle')
    File.exist?(gradle).should == true

    manifest = File.join(@config.project_dir, 'Gradle/iinappbillingservice/src/main/AndroidManifest.xml')
    File.exist?(manifest).should == true

    aidl_file = File.join(@config.project_dir, 'Gradle/iinappbillingservice/src/main/aidl/com/android/vending/billing/IInAppBillingService.aidl')
    File.exist?(aidl_file).should == true
  end
end
