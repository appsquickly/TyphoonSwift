Pod::Spec.new do |spec|
 
  spec.name = "TyphoonSwift"
  spec.summary = "Dependency injection for Swift. Light-weight, yet flexible and full-featured."
  spec.requires_arc = true

  spec.version = "0.0.1"
 
  spec.license = 'Apache2.0'
  spec.author = {'Jasper Blues, Aleksey Garbarev, Valeriy Popov, Igor Vasilenko & Contributors' => 'info@typhoonframework.org'}
  spec.homepage = 'http://www.typhoonframework.org'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  spec.source = {:git => 'http://git.appsquick.ly/typhoon/typhoon-swift.git', :branch => 'issue#1/create-cocoapod'}
  spec.source_files = 'Source/*.{swift}'

  spec.documentation_url = 'http://www.typhoonframework.org/docs/latest/api/'

end