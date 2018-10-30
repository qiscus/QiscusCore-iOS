Pod::Spec.new do |s|
s.name         = "QiscusCore"
s.version      = "0.1.3"
s.summary      = "Qiscus Core SDK for iOS"
s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC
s.homepage     = "https://qisc.us"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/qiscus/QiscusCore-iOS.git", :tag => "#{s.version}" }
s.platform      = :ios, "10.0"
s.ios.vendored_frameworks = 'QiscusCore.framework'
s.ios.frameworks = ["UIKit", "QuartzCore", "CFNetwork", "Security", "Foundation", "MobileCoreServices", "CoreData"]
s.dependency 'QiscusRealtime', '0.1.4'
s.dependency 'SwiftyJSON'
end
