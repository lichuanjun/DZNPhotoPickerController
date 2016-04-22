@version = "2.0.9"

Pod::Spec.new do |s|
  s.name         	  = "DZNPhotoPickerController"
  s.version      	  = @version
  s.summary      	  = "A photo search/picker for iOS using popular providers like 500px, Flickr, Intagram, Google Images, etc."
  s.description  	  = "This framework tries to mimic as close as possible the native UIImagePickerController API for iOS7, in terms of features, appearance and behaviour.And more,rely on good dzenbot, support roate and tap gesture "
  s.homepage   		  = "https://github.com/dzenbot/DZNPhotoPickerController"
  s.screenshots 	  = "https://raw.githubusercontent.com/dzenbot/DZNPhotoPickerController/master/Docs/screenshots.png"
  s.license     	  = { :type => 'MIT', :file => 'LICENSE' }
  s.author       	  = { "lichuanjun" => "lichuanjun1991@gmail.com" }
  
  s.source       	  = { :git => "https://github.com/lichuanjun/DZNPhotoPickerController.git", :commit => "ed94006870088e7c79cab6dbf7c2d7aba22d3cc3" }

  s.default_subspec = 'Core'
  s.resources       = 'Resources', 'Source/Resources/*'
  s.requires_arc 	  = true
  s.platform        = :ios, '7.0'

  s.public_header_files = 'Source/Classes/*/*.h'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Source/Classes/Core/*.{h,m}'
    ss.dependency   'DZNPhotoPickerController/Services'
    ss.dependency   'DZNPhotoPickerController/Editor'
    ss.dependency   'SDWebImage', '~> 3.7'
    ss.dependency   'DZNEmptyDataSet', '~> 1.7'
  end

  s.subspec 'Services' do |ss|
    ss.source_files = 'Source/Classes/Services/*.{h,m}',
                      'Source/Classes/Core/DZNPhotoPickerControllerConstants.{h,m}'

    ss.dependency 'AFNetworking', '~> 3.0'
    ss.prefix_header_contents = '#import <MobileCoreServices/MobileCoreServices.h>',
                                '#import <SystemConfiguration/SystemConfiguration.h>'
  end

  s.subspec 'Editor' do |ss|
    ss.source_files = 'Source/Classes/Editor/*.{h,m}',
                      'Source/Resources/*',
                      'Source/Classes/Core/DZNPhotoPickerControllerConstants.{h,m}'
  end
  
end
