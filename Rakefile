desc 'Build the gem'
task :gem do
  sh 'bundle exec gem build motion-gradle.gemspec'
  sh 'mkdir -p pkg'
  sh 'mv *.gem pkg/'
end

task :clean do
  FileUtils.rm_rf 'pkg'
end

desc 'Run all the specs'
task :spec do
  sh "bundle exec bacon #{FileList['spec/*_spec.rb'].join(' ')}"
end

task default: :spec
