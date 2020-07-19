Pod::Spec.new do |s|

s.name         = "QiscusRealtime"
s.version      = "1.4.0"
s.summary      = "Qiscus SDK Realtime Message for iOS"
s.description  = <<-DESC
QiscusRealtime SDK for iOS contains Chat User Interface.
DESC
s.homepage     = "https://qiscus.com"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/qiscus/QiscusRealtime-iOS.git", :tag => "#{s.version}" }
s.source_files  = "QiscusRealtime", "Source/QiscusRealtime/**/*.{h,m,swift,xib}"
s.ios.frameworks = ["CFNetwork", "Security", "Foundation", "MobileCoreServices"]
s.requires_arc = true
s.platform      = :ios, "10.0"

s.dependency 'CocoaMQTT', '1.3.0-rc.1'

end

