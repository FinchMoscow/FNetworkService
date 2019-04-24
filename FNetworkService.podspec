Pod::Spec.new do |s|

  s.platform                 = :ios
  s.ios.deployment_target    = '9.0'
  s.name                     = "FNetworkService"
  s.version                  = "0.0.1"
  s.summary                  = "NetworkService is a wrapper around Alamofire with generic Codable Result"
  s.requires_arc             = true

  s.description  = <<-DESC
  networking
                   DESC

  s.homepage     = "https://github.com/FinchMoscow/FNetworkService"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "Eugene" => "orexjeka@icloud.com" }

  s.source       = { :git => "https://github.com/FinchMoscow/FNetworkService.git", :tag => "#{s.version}" }

  s.source_files = "FNetworkService/*.{swift}"

  s.dependency 'Alamofire'

  s.swift_version = "4.2"

end
