#
# Be sure to run `pod lib lint ARCardFlicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ARCardFlicker'
  s.version          = '0.1.0'
  s.summary          = 'A short description of ARCardFlicker.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ksk.matsuo@gmail.com/ARCardFlicker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ksk.matsuo@gmail.com' => 'ksk.matsuo@gmail.com' }
  s.source           = { :git => 'https://github.com/ksk.matsuo@gmail.com/ARCardFlicker.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'ARCardFlicker/Classes/**/*'
  s.resource_bundles = {
    'ARCardFlicker' => ['ARCardFlicker/Assets/**/*']
  }

  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'

end