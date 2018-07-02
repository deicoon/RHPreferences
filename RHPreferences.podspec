Pod::Spec.new do |s|
  s.name         	= "RHPreferences"
  s.version      	= "0.0.1"
  s.summary      	= "A simple and easy Preferences window controller with multiple tabs for your next Mac application."
  s.homepage     	= "https://github.com/hons82/RHPreferences"
  s.license      	= { :type => 'BSD', :file => 'LICENSE.md' }
  s.author       	= { "Richard Heard" => "",
  						"Hannes Tribus" => "hons82@gmail.com" }
  s.source       	= { :git => "https://github.com/hons82/RHPreferences.git", :tag => "v#{s.version}" }
  s.platform     	= :osx, '10.6'
  s.requires_arc 	= true
  s.source_files 	= 'RHPreferences/*.{h,m}'
  s.resources 	 	= ["RHPreferences/*.xib"]
end
