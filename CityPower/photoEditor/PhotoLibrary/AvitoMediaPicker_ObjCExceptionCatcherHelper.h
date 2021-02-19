//
//  AvitoMediaPicker_ObjCExceptionCatcherHelper.h
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AvitoMediaPicker_ObjCExceptionCatcherHelper: NSObject

+ (void)try:(nonnull NS_NOESCAPE void(^)(void))tryBlock
      catch:(nonnull void(^)(NSException * _Nonnull))catchBlock
    finally:(nonnull void(^)(void))finallyBlock;

@end
