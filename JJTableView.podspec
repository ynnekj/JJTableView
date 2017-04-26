Pod::Spec.new do |s|
  s.name         = "JJTableView"
  s.version      = "0.1.1"
  s.summary      = "Support Interactive Reordering TableView."
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "Jkenny" => "jkenny.cn@gmail.com" }
  s.social_media_url   = "http://jkenny.cn"
  s.homepage     = 'https://github.com/ynnekj/JJTableView'
  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.source       = { :git => 'https://github.com/ynnekj/JJTableView.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.source_files  = "JJTableView/**/*.{h,m}"
  s.public_header_files = "JJTableView/**/*.{h}"

  s.frameworks = "UIKit"

end
