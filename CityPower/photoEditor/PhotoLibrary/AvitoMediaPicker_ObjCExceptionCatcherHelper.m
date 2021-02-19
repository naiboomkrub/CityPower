//
//  AvitoMediaPicker_ObjCExceptionCatcherHelper.m
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

#import "AvitoMediaPicker_ObjCExceptionCatcherHelper.h"

@implementation AvitoMediaPicker_ObjCExceptionCatcherHelper

+ (void)try:(NS_NOESCAPE void(^)(void))tryBlock
      catch:(void(^)(NSException *))catchBlock
    finally:(void(^)(void))finallyBlock
{
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        catchBlock(exception);
    }
    @finally {
        finallyBlock();
    }
}

@end
