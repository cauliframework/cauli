#
#  Be sure to run `pod spec lint Cauli.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #
  s.name         = "Cauliframework"
  s.version      = "1.0.1"
  s.summary      = "Helps you to intercept network requests."
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
  Cauli is a network debugging framework featuring a plugin infrastructure to hook into selected request and responses as well as recording and displaying performed requests. It provides a wide range of possibilities. For example from inspecting network traffic to mock UnitTests. Missing something fancy? How about writing your own Plugin.
                   DESC

  s.homepage     = "https://cauli.works"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors            = { "Cornelius Horstmann" => "cornelius@brototyp.de", "Pascal Stüdlein" => "mail@pascal-stuedlein.de" }
  s.ios.deployment_target = "8.0"

  # watchOS and tvOS are currently not tested
  # s.watchos.deployment_target = "3.0"
  # s.tvos.deployment_target = "10.0"
  s.source       = { :git => "https://github.com/cauliframework/cauli.git", :tag => "#{s.version}" }
  s.source_files  = "Cauli", "Cauli/**/*.swift"
  s.swift_version = '4.2'

  s.resources = 'Cauli/**/*.xib'

end
