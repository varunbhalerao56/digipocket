Pod::Spec.new do |s|
  s.name         = 'llama'
  s.version      = '0.1.2'
  s.summary      = 'Dart binding for llama.cpp'
  s.description  = 'High-level Dart / Flutter bindings for llama.cpp.'
  s.homepage     = 'https://github.com/varunbhalerao56/quiz_wrapper'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Varun Bhalerao' => 'varunbhalerao5902@gmail.com' }
  s.source       = { :http => 'file:' + __dir__ }

  s.platform     = :ios, '15.6'

  # Podspec is in project root, dist/ is also in root
  s.preserve_paths = 'dist/Llama.xcframework'
  s.vendored_frameworks = 'dist/Llama.xcframework'

  s.dependency 'Flutter'
  s.frameworks = 'Metal', 'Accelerate', 'Foundation'
  s.libraries = 'c++'


  s.pod_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO',
    'DEFINES_MODULE' => 'YES',
    'STRIP_INSTALLED_PRODUCT' => 'NO',
    'STRIP_STYLE' => 'non-global',
    'STRIPFLAGS' => '-x',
    'DEAD_CODE_STRIPPING' => 'NO'
  }
end