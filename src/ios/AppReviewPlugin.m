#import "AppReviewPlugin.h"
#import "StoreKit/StoreKit.h"

@implementation AppReviewPlugin

- (void)requestReview:(CDVInvokedUrlCommand *)command {
    CDVPluginResult* pluginResult;
    if (@available(iOS 14.0, *)) {
        if ([SKStoreReviewController class]) {
            _currentScene = (UIWindowScene *)[[[[UIApplication sharedApplication] connectedScenes] allObjects] firstObject];
            if ([_currentScene isKindOfClass:[UIWindowScene class]] && _currentScene.activationState == UISceneActivationStateForegroundActive) {
                [SKStoreReviewController requestReviewInScene:_currentScene];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
            else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"App is not in Foreground"];
            }
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Rating dialog requires iOS 14.0+"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)openStoreScreen:(CDVInvokedUrlCommand*)command {
    NSString* packageName = [command.arguments objectAtIndex:0];
    if ([packageName isKindOfClass:[NSNull class]]) {
        packageName = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
    }
    BOOL writeReview = [[command.arguments objectAtIndex:1] boolValue];
    NSString* trackId = [self fetchTrackId:packageName];

    CDVPluginResult* pluginResult;
    if (trackId) {
        NSString* storeURL = [NSString stringWithFormat:@"https://apps.apple.com/app/id%@", trackId];

        if (writeReview) {
            storeURL = [NSString stringWithFormat:@"%@?action=write-review", storeURL];
        }

        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:storeURL] options:@{} completionHandler:nil];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Can't get trackId"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSString*)fetchTrackId:(NSString*)packageName {
    NSString* lookupURL = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", packageName];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:lookupURL]];
    NSDictionary* lookup = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    if ([lookup[@"resultCount"] integerValue] == 1) {
        return lookup[@"results"][0][@"trackId"];
    } else {
        return nil;
    }
}

@end
