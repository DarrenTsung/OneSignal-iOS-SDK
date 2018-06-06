//
//  InfluxDb.h
//  OneSignalDemo
//
//  Created by Darren Tsung on 6/6/18.
//  Copyright © 2018 OneSignal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfluxDb : NSObject

+ (void)sendToInfluxDBWithEvent:(NSString*)event WithNotificationId:(NSString*)notificationID;

@end
