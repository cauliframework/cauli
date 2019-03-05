include FileUtils::Verbose

namespace :test do
  desc 'Prepare tests'
  task :prepare do
  end

  desc 'Run the Cauli Unit tests'
  task ios: :prepare do
    run_tests('Cauliframework', 'iphonesimulator', 'platform=iOS Simulator,name=iPhone 6,OS=12.1')
    build_failed('iPhone 6, iOS 12.0') unless $?.success?
    run_tests('Cauliframework', 'iphonesimulator', 'platform=iOS Simulator,name=iPhone 6,OS=11.4')
    build_failed('iPhone 6, iOS 11.4') unless $?.success?
    run_tests('Cauliframework', 'iphonesimulator', 'platform=iOS Simulator,name=iPhone 6,OS=10.3.1')
    build_failed('iPhone 6, iOS 10.0') unless $?.success?
    run_tests('Cauliframework', 'iphonesimulator', 'platform=iOS Simulator,name=iPhone 6,OS=10.3.1')
    build_failed('iPhone 6, iOS 9.0') unless $?.success?
  end

  desc 'Build the Cauli iOS Example Application'
  task ios_example: :prepare do
    run_build('cauli-ios-example', 'iphonesimulator')
    build_failed('cauli-ios-example') unless $?.success?
  end
end


desc 'Run the Cauli tests'
task :test do
  Rake::Task['test:ios'].invoke
  Rake::Task['test:ios_example'].invoke
end

task default: 'test'


private

def run_build(scheme, sdk, destination = 'platform=iOS Simulator,name=iPhone 6,OS=12.1')
  sh("xcodebuild -workspace Example/cauli-ios-example/cauli-ios-example.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -destination '#{destination}' -configuration Release clean build | xcpretty -c ; exit ${PIPESTATUS[0]}") rescue nil
end

def run_tests(scheme, sdk, destination = 'platform=iOS Simulator,name=iPhone 6,OS=12.1')
  sh("xcodebuild -workspace Cauliframework.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -destination '#{destination}' -configuration Debug clean test | xcpretty -c ; exit ${PIPESTATUS[0]}") rescue nil
end

def build_failed(platform)
  puts red("#{platform} build failed")
  exit $?.exitstatus
end

def tests_failed(platform)
  puts red("#{platform} unit tests failed")
  exit $?.exitstatus
end

def red(string)
  "\033[0;31m! #{string}"
end
