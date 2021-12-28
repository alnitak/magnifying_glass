#import "MagnifyingGlassPlugin.h"
#if __has_include(<magnifying_glass/magnifying_glass-Swift.h>)
#import <magnifying_glass/magnifying_glass-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "magnifying_glass-Swift.h"
#endif

@implementation MagnifyingGlassPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMagnifyingGlassPlugin registerWithRegistrar:registrar];
}
@end
