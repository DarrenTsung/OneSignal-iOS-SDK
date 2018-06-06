//
//  InfluxDb.h
//  OneSignalDemo
//
//  Created by Darren Tsung on 6/6/18.
//  Copyright © 2018 OneSignal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface InfluxDb : NSObject

+ (void)sendToInfluxDBWithEvent:(NSString*)event WithNotificationTitle:(NSString*)title AndMessage:(NSString*)message;
+ (void)sendToInfluxDBWithEvent:(NSString*)event;
+ (void)setCurrentLocation:(CLLocation*)location;

@end
