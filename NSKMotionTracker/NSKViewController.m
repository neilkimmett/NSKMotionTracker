//
//  NSKViewController.m
//  NSKMotionTracker
//
//  Created by Neil Kimmett on 08/10/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

@import CoreLocation;

#import "NSKViewController.h"

@interface NSKViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation NSKViewController

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height, 0, 0, 0);
    textView.editable = NO;
    self.view = textView;
    self.textView = textView;
    
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    _locationManager = locationManager;
}

- (void)updateTextViewText
{
    NSString *text = [[NSString alloc] initWithContentsOfFile:[self locationFilename]
                                                     encoding:NSUTF8StringEncoding
                                                               error:nil];
    self.textView.text = text;
}

- (NSString *)locationFilename
{
    NSArray *documentsSearchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsSearchPaths count] == 0 ? nil : [documentsSearchPaths objectAtIndex:0];
    NSString *locationsFile = [documentsDirectory stringByAppendingPathComponent:@"locations.txt"];
    return locationsFile;
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    UIBackgroundTaskIdentifier bgTask = 0;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        }];
    }
    
    NSString *locationsString = @"";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    for (CLLocation *location in locations) {
        NSString *loc = [NSString stringWithFormat:@"%@\t%f\t%f\n", [dateFormatter stringFromDate:location.timestamp], location.coordinate.latitude, location.coordinate.longitude];
        locationsString = [locationsString stringByAppendingString:loc];
    }
    
    NSString *locationsFile = [self locationFilename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:locationsFile]) {
        [@"" writeToFile:locationsFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:locationsFile];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[locationsString dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle synchronizeFile];
    [fileHandle closeFile];
    [self updateTextViewText];
    
    if (bgTask != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}

@end
