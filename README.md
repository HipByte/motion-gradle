# motion-gradle

motion-gradle allows RubyMotion projects to integrate with
[Gradle](https://gradle.org/) to manage your dependencies.


## Installation

You need to have gradle installed:

```
$ brew install gradle
```

And the gem installed:

```
$ [sudo] gem install motion-gradle
```

Or if you use Bundler:

```ruby
gem 'motion-gradle'
```

You also need to install `Extras/Android Support Repository` and `Extras/Google Repository` with the Android SDK Manager gui.

![android-sdk-manager](https://raw.githubusercontent.com/jjaffeux/motion-gradle/master/images/android-sdk-manager.png)


## Setup

Edit the `Rakefile` of your RubyMotion project and add the following require lines:

 ```ruby
 require 'rubygems'
 require 'motion-gradle'
 ```

### Dependencies

From version 1.1.0 you can use the same gradle dependency string that Java users use.

  ```ruby
  Motion::Project::App.setup do |app|
    # ...
    app.gradle do
      dependency 'net.sf.ehcache:ehcache:2.9.0'
      dependency 'com.joanzapata.pdfview:android-pdfview:1.0.+@aar'
      dependency 'com.danikula:videocache:2.3.1' do
        exclude module: 'android', group: 'com.google.android'
      end
    end
  end
  ```

### Configuration

If the `gradle` command is not found in your PATH, you can configure it:

```ruby
Motion::Project::App.setup do |app|
  # ...
  app.gradle.path = '/some/path/gradle'
end
```

### Repositories :

```ruby
Motion::Project::App.setup do |app|
  # ...
  app.gradle do
    repository 'https://bintray.com/bintray/jcenter'
    repository 'http://dl.bintray.com/austintaylor/gradle'
  end
end
```

### Java libraries

```ruby
Motion::Project::App.setup do |app|
  # ...
  app.gradle do
    library 'mylib', path: '/Users/joffreyjaffeux/Projects/mylib'
   end
end
```

If relative path is used it's relative to your Rakefile, if you don't specify a path it will search in your_app/my_lib.

### Plugins

```ruby
Motion::Project::App.setup do |app|
  # ...
  app.gradle do
    plugin 'com.google.gms.google-services'
   end
end
```

### Classpaths

```ruby
Motion::Project::App.setup do |app|
  # ...
  app.gradle do
    classpath 'com.google.gms:google-services:1.3.0-beta1'
  end
end
```

### Aidl

```ruby
Motion::Project::App.setup do |app|
  # ...
  app.gradle do
    aidl 'com.android.vending.billing', './vendor/IInAppBillingService.aidl'
  end
end
```


## Tasks

To tell motion-gradle to download your dependencies, run the following rake
task:

```
$ [bundle exec] rake gradle:install
```

After a `rake clean:all` you will need to run the install task agin.

That’s all.


## Known issues

* Clunky .aar support, if you can provide failing cases of libs using .aar it would be great
* Issue with iconify : http://hipbyte.myjetbrains.com/youtrack/issue/RM-867
