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
  s.swift_version    = '4.2'
  s.summary          = 'Display flickable cards that are like a matching service in AR.'

  s.description      = <<-DESC
Display flickable cards that are like a matching service in AR.
Flicking to forward will send like.
Flicking to other direction will skip card.
                       DESC

  s.homepage         = 'https://github.com/Matzo/ARCardFlicker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Matzo' => 'ksk.matsuo@gmail.com' }
  s.source           = { :git => 'https://github.com/Matzo/ARCardFlicker.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.4'

  s.source_files = 'ARCardFlicker/Classes/**/*'
  s.resource_bundles = {
    'ARCardFlicker' => ['ARCardFlicker/Assets/**/*']
  }

  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'

end
