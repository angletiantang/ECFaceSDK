#
# Be sure to run `pod lib lint EyeCoolFaceSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ECFaceSDK'
  s.version          = '4.3.6'
  s.summary          = 'EyeCool technology face detection for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
本次更新的内容:
1.支持自动布局；
2.优化整体检活逻辑；
3.解决ncnn冲突问题；
4.解决opencv冲突问题；
5.优化防Hack攻击;
                       DESC

  s.homepage         = 'https://github.com/angletiantang/ECFaceSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'angletiantang' => 'guojianheng@eyecool.cn' }
  s.source           = { :git => 'https://github.com/angletiantang/ECFaceSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  # 资源文件
  s.source_files = 'EyeCoolFaceSDK/include/*.{h,m,mm}','EyeCoolFaceSDK/include/DACircularProgress/*.{h,m}'
  
  # bundle资源文件
  s.resource = 'EyeCoolFaceSDK/ECFaceSDK.bundle'
  
  # 需要引入的.a静态包
  s.vendored_libraries = 'EyeCoolFaceSDK/libECFaceSDK.a'
  # 系统需要引入的静态包 libc++.1.tbd libc.tbd
  #s.libraries = 'c++.1', 'c'
  
  # s.resource_bundles = {
  #   'EyeCoolFaceSDK' => ['EyeCoolFaceSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
