Pod::Spec.new do |spec|
  spec.name             = 'TSNPeerNetworking'
  spec.platform         = :ios
  spec.version          = '1.0'
  spec.license          = { :type => 'MIT' }
  spec.homepage         = 'https://github.com/softwarenerd/TSNPeerNetworking'
  spec.author           = { 'Brian Lambert' => 'brianlambert@softwarenerd.org' }
  spec.summary          = 'Peer networking for iOS.'
  spec.source           = { :git => 'https://github.com/softwarenerd/TSNPeerNetworking.git', :tag => 'v1.0' }
  spec.source_files     = 'Source/*'
  spec.framework        = 'Foundation', 'MultipeerConnectivity'
  spec.requires_arc     = true
  spec.ios.deployment_target = '9.0'
end