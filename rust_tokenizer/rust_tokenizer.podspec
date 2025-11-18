Pod::Spec.new do |s|
    s.name             = 'rust_tokenizer'
    s.version          = '0.0.3'
    s.summary          = 'Rust tokenizer library'
    s.homepage         = 'http://example.com'
    s.author           = { 'Your Company' => 'email@example.com' }
    s.source           = { :path => '.' }
    s.source_files     = '*.c'

    s.ios.deployment_target = '13.0'
    s.macos.deployment_target = '10.13'

    s.script_phase = {
      :name => 'Build Rust library',
      :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../rust_tokenizer rust_tokenizer',
      :execution_position => :before_compile,
      :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
      :output_files => ["${BUILT_PRODUCTS_DIR}/librust_tokenizer.a"],
    }

    s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
      'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/librust_tokenizer.a',
    }
end