// Copyright 2014 Google Inc. All Rights Reserved.

#import "GADUInterstitial.h"

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "GADUPluginUtil.h"
#import "UnityInterface.h"

@interface GADUInterstitial () <GADInterstitialDelegate>
@end

@implementation GADUInterstitial

- (id)initWithInterstitialClientReference:(GADUTypeInterstitialClientRef *)interstitialClient
                                 adUnitID:(NSString *)adUnitID {
  self = [super init];
  if (self) {
    _interstitialClient = interstitialClient;
    _interstitial = [[GADInterstitial alloc] initWithAdUnitID:adUnitID];
    _interstitial.delegate = self;

    __weak GADUInterstitial *weakSelf = self;
    _interstitial.paidEventHandler = ^void(GADAdValue *_Nonnull adValue) {
      GADUInterstitial *strongSelf = weakSelf;
      if (strongSelf.paidEventCallback) {
        int64_t valueInMicros =
            [adValue.value decimalNumberByMultiplyingByPowerOf10:6].longLongValue;
        strongSelf.paidEventCallback(
            strongSelf.interstitialClient, (int)adValue.precision, valueInMicros,
            [adValue.currencyCode cStringUsingEncoding:NSUTF8StringEncoding]);
      }
    };
  }
  return self;
}

- (void)dealloc {
  _interstitial.delegate = nil;
}

- (void)loadRequest:(GADRequest *)request {
  [self.interstitial loadRequest:request];
}

- (BOOL)isReady {
  return self.interstitial.isReady;
}

- (void)show {
  if (self.interstitial.isReady) {
    UIViewController *unityController = [GADUPluginUtil unityGLViewController];
    [self.interstitial presentFromRootViewController:unityController];
  } else {
    NSLog(@"GoogleMobileAdsPlugin: Interstitial is not ready to be shown.");
  }
}

- (NSString *)mediationAdapterClassName {
  return self.interstitial.responseInfo.adNetworkClassName;
}

- (GADResponseInfo *)responseInfo {
  return self.interstitial.responseInfo;
}

#pragma mark GADInterstitialDelegate implementation

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad {
  if (self.adReceivedCallback) {
    self.adReceivedCallback(self.interstitialClient);
  }
}
- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error {
  if (self.adFailedCallback) {
    self.adFailedCallback(self.interstitialClient, (__bridge GADUTypeErrorRef )error);
  }
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)ad {
  if ([GADUPluginUtil pauseOnBackground]) {
    UnityPause(YES);
  }

  if (self.willPresentCallback) {
    self.willPresentCallback(self.interstitialClient);
  }
}

- (void)interstitialWillDismissScreen:(GADInterstitial *)ad {
  // Callback is not forwarded to Unity.
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad {
  extern bool _didResignActive;
  if(_didResignActive) {
    // We are in the middle of the shutdown sequence, and at this point unity runtime is already destroyed.
    // We shall not call unity API, and definitely not script callbacks, so nothing to do here
    return;
  }

  if (UnityIsPaused()) {
    UnityPause(NO);
  }

  if (self.didDismissCallback) {
    self.didDismissCallback(self.interstitialClient);
  }
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad {
  if (self.willLeaveCallback) {
    self.willLeaveCallback(self.interstitialClient);
  }
}

@end
