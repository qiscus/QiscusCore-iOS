Pod::Spec.new do |s|
s.name         = "QiscusCore"
s.version      = "1.5.11-beta.1"
s.summary      = "Qiscus Core SDK for iOS"
s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC
s.homepage     = "https://qiscus.com"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/qiscus/QiscusCore-iOS.git", :tag => "#{s.version}" }
s.source_files  = "QiscusCore", "Source/QiscusCore/**/*.{h,m,swift,xib}"
#s.resources 	= "Source/QiscusCore/**/*.xcassets"
s.resource_bundles = {
    'QiscusCore' => ['Source/QiscusCore/**/*.{lproj,xib,xcassets,imageset,png,xcdatamodeld,xcdatamodel}']
}
s.platform      = :ios, "10.0"
s.ios.frameworks = ["UIKit", "QuartzCore", "CFNetwork", "Security", "Foundation", "MobileCoreServices", "CoreData"]
s.dependency 'QiscusRealtime', '1.4.2'
s.dependency 'SwiftyJSON'
end
