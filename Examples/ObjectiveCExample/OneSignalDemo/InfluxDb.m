//
//  InfluxDb.m
//  OneSignalDemo
//
//  Created by Darren Tsung on 6/6/18.
//  Copyright © 2018 OneSignal. All rights reserved.
//

#import "InfluxDb.h"

@implementation InfluxDb

CLLocation *currentLocation;

+ (void)setCurrentLocation:(CLLocation*)location {
    currentLocation = location;
}

+ (void)sendToInfluxDBWithEvent:(NSString*)event WithNotificationTitle:(NSString*)title AndMessage:(NSString*)message {
    NSString *payload = [NSString stringWithFormat:@"events,player_id=%@ event_type=\"%@\",title=\"%@\",message=\"%@\",lat=%f,long=%f", @"be9e6837-a2e4-493a-9321-7230e6341b90", event, title, message, currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    [InfluxDb sendToInfluxDBWithPayload:payload];
}

+ (void)sendToInfluxDBWithEvent:(NSString*)event {
    NSString *payload = [NSString stringWithFormat:@"events,player_id=%@ event_type=\"%@\",lat=%f,long=%f", @"be9e6837-a2e4-493a-9321-7230e6341b90", event, currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    [InfluxDb sendToInfluxDBWithPayload:payload];
}

+ (void)sendToInfluxDBWithPayload:(NSString *)payload {
    NSData *postData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength = [NSString stringWithFormat:@"%lu", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request setURL:[NSURL URLWithString:@"http://147.75.192.45:8086/write?db=onesignal_dev"]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSLog(@"SENDING OFF INFLUXDB EVENT!");
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *sendTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Received data: %@, response: %@, error: %@", data, response, error);
    }];
    [sendTask resume];
}


@end
