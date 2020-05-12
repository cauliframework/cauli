include FileUtils::Verbose

namespace :test do
  desc 'Prepare tests'
  task :prepare do
  end

  desc 'Run the Cauli Unit tests'
  task ios: :prepare do
    run_tests('Cauliframework', 'iphonesimulator', 'iPhone 6', '12.2')
    run_tests('Cauliframework', 'iphonesimulator', 'iPhone 6', '11.4')
    run_tests('Cauliframework', 'iphonesimulator', 'iPhone 6', '10.3.1')
  end

  desc 'Build the Cauli iOS Example Application'
  task ios_example: :prepare do
    run_build('cauli-ios-example', 'iphonesimulator', 'iPhone 6', '12.2')
  end
end

namespace :package_manager do
  desc 'Prepare tests'
  task :prepare do
  end

  desc 'Builds the project with the Swift Package Manager'
  task spm: :prepare do
    sh("swift build \
    -Xswiftc \"-sdk\" -Xswiftc \"\`xcrun --sdk iphonesimulator --show-sdk-path\`\" \
    -Xswiftc \"-target\" -Xswiftc \"x86_64-apple-ios12.0-simulator\"") rescue nil
    package_manager_failed('Swift Package Manager') unless $?.success?
  end
end


desc 'Run the Cauli tests'
task :test do
  Rake::Task['test:ios'].invoke
  Rake::Task['test:ios_example'].invoke
  Rake::Task['package_manager:spm'].invoke
end

task default: 'test'


private

def run_build(scheme, sdk, device = 'iPhone 6', os = '12.2')
  sh("xcodebuild -workspace Example/cauli-ios-example/cauli-ios-example.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -destination 'platform=iOS Simulator,name=#{device},OS=#{os}' -configuration Release clean build | xcpretty -c ; exit ${PIPESTATUS[0]}") rescue nil
  build_failed("#{device}, #{os}") unless $?.success?
end

def run_tests(scheme, sdk, device = 'iPhone 6', os = '12.2')
  sh("xcodebuild -workspace Cauliframework.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -destination 'platform=iOS Simulator,name=#{device},OS=#{os}' -configuration Debug clean test | xcpretty -c ; exit ${PIPESTATUS[0]}") rescue nil
  tests_failed("#{device}, #{os}") unless $?.success?
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
  "\033[0;31m! #{string}\033[0m"
end
