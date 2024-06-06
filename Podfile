# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'Drive2011' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'GoogleAPIClientForREST/Drive'
  pod 'Apptics-Swift'

  # Pre build script will register the app version, upload dSYM file to the server and add apptics specific information to the main info.plist which will be used by the SDK.
  script_phase :name => 'Apptics pre build', 
  :script => 'sh "./Pods/Apptics-SDK/scripts/run" --upload-symbols-for-configurations="Release, Appstore"', 
  :execution_position => :before_compile
  # Pods for Drive2011
end

