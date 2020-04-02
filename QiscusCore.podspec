Pod::Spec.new do |s|
s.name         = "QiscusCore"
s.version      = "3.0.0-beta.3"
s.summary      = "Qiscus Core SDK for iOS"
s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC
s.homepage     = "https://qiscus.com"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/qiscus/QiscusCore-iOS.git", :tag => "#{s.version}" }
s.platform      = :ios, "9.0"
s.ios.vendored_frameworks = 'QiscusCore.framework'
s.ios.frameworks = ["UIKit", "QuartzCore", "CFNetwork", "Security", "Foundation", "MobileCoreServices", "CoreData"]
s.dependency 'QiscusRealtime', '1.2.0'
s.dependency 'SwiftyJSON'
end
