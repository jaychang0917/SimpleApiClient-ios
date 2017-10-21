Pod::Spec.new do |s|
s.name = 'SimpleApiClient'
s.version = '0.1.0'
s.summary = 'A configurable api client based on Alamofire4 and RxSwift4 for iOS'
s.homepage = 'https://github.com/jaychang0917/SimpleApiClient-ios'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.author = { 'Jay Chang' => 'jaychang0917@gmail.com' }
s.source = { :git => 'https://github.com/jaychang0917/SimpleApiClient-ios.git', :tag => s.version.to_s }

s.ios.deployment_target = '8.0'

s.source_files = 'SimpleApiClient/Classes/**/*'

s.dependency "Alamofire", "~> 4.5"
s.dependency "RxSwift", "~> 4.0"
end

