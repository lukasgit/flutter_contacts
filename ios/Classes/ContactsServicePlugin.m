#import "ContactsServicePlugin.h"
#import <contacts_service/contacts_service-Swift.h>

@implementation ContactsServicePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (@available(iOS 9.0, *)) {
        [SwiftContactsServicePlugin registerWithRegistrar:registrar];
    } else {
        // Fallback on earlier versions
    }
}
@end
