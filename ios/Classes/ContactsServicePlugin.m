#import "ContactsServicePlugin.h"
#if __has_include(<contacts_service/contacts_service-Swift.h>)
#import <contacts_service/contacts_service-Swift.h>
#else
#import "contacts_service-Swift.h"
#endif

@implementation ContactsServicePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftContactsServicePlugin registerWithRegistrar:registrar];
}
@end
