Pod::Spec.new do |s|
  s.name         = 'YUGPUImageCVPixelBufferInput'
  s.version      = '0.2'
  s.author       = { 'YuAo' => 'me@imyuao.com' }
  s.homepage     = 'https://github.com/YuAo/YUGPUImageCVPixelBufferInput'
  s.summary      = 'CVPixelBuffer input for GPUImage'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.source       = {:git => 'https://github.com/YuAo/YUGPUImageCVPixelBufferInput.git', :tag => '0.2'}
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/**/*.{h,m}'
  s.dependency 'GPUImage'
end
