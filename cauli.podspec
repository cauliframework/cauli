Pod::Spec.new do |s|

  s.name         = "cauli"
  s.version      = "0.1"
  s.summary      = "Stay health. Eat cauli."

  s.description  = <<-DESC
                    cauli is a tool for recording and manipulating network traffic.
                   DESC

  s.homepage     = "https://bitbucket.org/Achelsmar/cauli"

  s.license      = "MIT"

  s.author      = { "Pascal Stüdlein" => "stuedlein@tbointeractive.com" }

  s.platform     = :ios, "10.0"

  s.source       = { :git => "git@private:Achelsmar/cauli.git", :branch => 'develop' }

  s.source_files = "cauli/cauli/**/*.swift"
end
