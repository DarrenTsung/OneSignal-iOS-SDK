/**
 * Modified MIT License
 *
 * Copyright 2017 OneSignal
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * 2. All copies of substantial portions of the Software may only be used in connection
 * with services provided by OneSignal.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "ViewController.h"
#import "AppDelegate.h"
#import "InfluxDb.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *subscriptionStatusSwitch;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UILabel *subscriptionStatusLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoutEmailTrailingSpaceConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *setEmailActivityIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *logoutEmailActivityIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton *setEmailButton;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if ([OneSignal getPermissionSubscriptionState].subscriptionStatus.subscribed) {
        self.subscriptionStatusSwitch.on = true;
        self.subscriptionStatusSwitch.userInteractionEnabled = true;
        self.registerButton.backgroundColor = [UIColor greenColor];
        self.registerButton.userInteractionEnabled = false;
    }
    
    [OneSignal addPermissionObserver:self];
    [OneSignal addSubscriptionObserver:self];
    [OneSignal addEmailSubscriptionObserver:self];
    
    self.emailTextField.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (AppDelegate*)appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (void)displaySettingsNotification {
    UIAlertAction *settings = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Tapped Settings");
        if ([[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [self displayAlert:@"Settings" withMessage:@"Please turn on notifications by going to Settings > Notifications > Allow Notifications" actions:@[settings, cancel]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)displayError:(NSString *)errorText {
    [self displayAlert:@"An Error Occurred" withMessage:errorText actions:@[]];
}

- (void)displayAlert:(NSString *)title withMessage:(NSString *)message actions:(NSArray<UIAlertAction *>*)actions {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        if (!actions || actions.count == 0) {
            [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:nil]];
        } else {
            for (UIAlertAction *action in actions) {
                [controller addAction:action];
            }
        }
        [self presentViewController:controller animated:true completion:nil];
    });
}

- (void)changeLoadingButtonAnimationStateWithTrailingConstraint:(NSLayoutConstraint *)constraint withActivityIndicatorView:(UIActivityIndicatorView *)activityIndicatorView animatingState:(BOOL)isAnimating {
    constraint.constant = isAnimating ? 36.0 : 0.0;
    if (isAnimating) {
        [activityIndicatorView startAnimating];
    }
    
    [UIView animateWithDuration:0.15 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!isAnimating) {
            [activityIndicatorView stopAnimating];
        }
    }];
}

#pragma mark IBActions
- (IBAction)sendTagsButtonPressed:(UIButton *)sender {
    [OneSignal sendTags:@{@"key" : @"value"} onSuccess:^(NSDictionary *result) {
        NSLog(@"success!");
    } onFailure:^(NSError *error) {
        NSLog(@"Error - %@", error.localizedDescription);
    }];
}

- (IBAction)getTagsButtonPressed:(UIButton *)sender {
    [OneSignal getTags:^(NSDictionary *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textView.text = [NSString stringWithFormat:@"Successfully got tags: \n\n%@", result];
        });
    } onFailure:^(NSError *error) {
        [self displayError:error.localizedDescription];
    }];
}

- (IBAction)updateTagsButtonPressed:(UIButton *)sender {
    NSDictionary *exampleTags = @{@"some_key" : @"some_value", @"users_name" : @"Jon", @"finished_level" : @30, @"has_followers" : @(false), @"added_review" : @(false)};
    
    [OneSignal sendTags:exampleTags onSuccess:^(NSDictionary *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textView.text = [NSString stringWithFormat: @"Successfully Sent Tags: \n\n%@", result];
        });
    } onFailure:^(NSError *error) {
        [self displayError:error.localizedDescription];
    }];
    
}

- (IBAction)getIdsAvailableButtonPressed:(UIButton *)sender {
    OSPermissionSubscriptionState *state = [OneSignal getPermissionSubscriptionState];
    NSString *pushToken = state.subscriptionStatus.pushToken;
    NSString *userId = state.subscriptionStatus.userId;
    
    if (pushToken) {
        NSDictionary *content = @{
                                  @"include_player_ids" : @[userId],
                                  @"contents" : @{@"en" : @"Wendy! It's been 10 days since you last bought Starbucks coffee! Come back! ☕😘"},
                                  @"headings" : @{@"en" : @"Why you no buy my coffee? 😞"},
                                  // If want to open a url with in-app browser
                                  //"url": "https://google.com",
                                  // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
                                  @"data" : @{@"OpenURL" : @"https://imgur.com"},
                                  @"ios_badgeType" : @"Increase",
                                  @"ios_badgeCount" : @1
                                  };
        
        [OneSignal postNotification:content onSuccess:^(NSDictionary *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textView.text = [NSString stringWithFormat:@"Sent notification with payload: \n\n%@", content];
            });
        } onFailure:^(NSError *error) {
            [self displayError:error.localizedDescription];
        }];
    } else {
        [self displayError:@"Could not send push notification: current user does not have a push token"];
    }
}

- (IBAction)syncEmailButtonPressed:(UIButton *)sender {
    OSPermissionSubscriptionState *state = [OneSignal getPermissionSubscriptionState];
    NSString *pushToken = state.subscriptionStatus.pushToken;
    NSString *userId = state.subscriptionStatus.userId;
    
    if (pushToken) {
        NSDictionary *content = @{
                                  @"include_player_ids" : @[userId],
                                  @"contents" : @{@"en" : @"Rate your coffee experience and send a coffee to a friend 👯‍♀️"},
                                  @"headings" : @{@"en" : @"Thanks for coming in! Please rate us! ✅"},
                                  // If want to open a url with in-app browser
                                  //"url": "https://google.com",
                                  // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
                                  @"data" : @{@"OpenURL" : @"https://imgur.com"},
                                  @"ios_badgeType" : @"Increase",
                                  @"ios_badgeCount" : @1
                                  };
        
        [OneSignal postNotification:content onSuccess:^(NSDictionary *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textView.text = [NSString stringWithFormat:@"Sent notification with payload: \n\n%@", content];
            });
        } onFailure:^(NSError *error) {
            [self displayError:error.localizedDescription];
        }];
    } else {
        [self displayError:@"Could not send push notification: current user does not have a push token"];
    }
}

- (IBAction)promptLocationButtonPressed:(UIButton *)sender {
    OSPermissionSubscriptionState *state = [OneSignal getPermissionSubscriptionState];
    NSString *pushToken = state.subscriptionStatus.pushToken;
    NSString *userId = state.subscriptionStatus.userId;
    
    if (pushToken) {
        NSDictionary *content = @{
                                  @"include_player_ids" : @[userId],
                                  @"contents" : @{@"en" : @"Hi Wendy - we see you're close to a Starbucks - come in and get coffee on us! 🙌"},
                                  @"headings" : @{@"en" : @"Free cup of Starbucks 💸"},
                                  // If want to open a url with in-app browser
                                  //"url": "https://google.com",
                                  // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
                                  @"data" : @{@"OpenURL" : @"https://imgur.com"},
                                  @"ios_badgeType" : @"Increase",
                                  @"ios_badgeCount" : @1
                                  };
        
        [OneSignal postNotification:content onSuccess:^(NSDictionary *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textView.text = [NSString stringWithFormat:@"Sent notification with payload: \n\n%@", content];
            });
        } onFailure:^(NSError *error) {
            [self displayError:error.localizedDescription];
        }];
    } else {
        [self displayError:@"Could not send push notification: current user does not have a push token"];
    }
}

- (IBAction)sendFirstExampleNotificationButtonPressed:(UIButton *)sender {
    OSPermissionSubscriptionState *state = [OneSignal getPermissionSubscriptionState];
    NSString *pushToken = state.subscriptionStatus.pushToken;
    NSString *userId = state.subscriptionStatus.userId;
    
    if (pushToken) {
        NSDictionary *content = @{
          @"include_player_ids" : @[userId],
          @"contents" : @{@"en" : @"Thanks for setting up Apple Pay - Get 20% off your next purchase on us! 🤑"},
          @"headings" : @{@"en" : @"Apple Pay 💰💰"},
          // If want to open a url with in-app browser
          //"url": "https://google.com",
          // If you want to deep link and pass a URL to your webview, use "data" parameter and use the key in the AppDelegate's notificationOpenedBlock
          @"data" : @{@"OpenURL" : @"https://imgur.com"},
          @"ios_badgeType" : @"Increase",
          @"ios_badgeCount" : @1
        };
        
        [OneSignal postNotification:content onSuccess:^(NSDictionary *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textView.text = [NSString stringWithFormat:@"Sent notification with payload: \n\n%@", content];
            });
        } onFailure:^(NSError *error) {
            [self displayError:error.localizedDescription];
        }];
    } else {
        [self displayError:@"Could not send push notification: current user does not have a push token"];
    }
}

- (IBAction)sendSecondExampleNotificationButtonPressed:(UIButton *)sender {
    OSPermissionSubscriptionState *state = [OneSignal getPermissionSubscriptionState];
    NSString *pushToken = state.subscriptionStatus.pushToken;
    NSString *userId = state.subscriptionStatus.userId;
    
    if (pushToken) {
        NSDictionary *content = @{
          @"include_player_ids" : @[userId],
          @"headings" : @{@"en" : @"Welcome Starbucks Mobile ☕"},
          @"contents" : @{@"en" : @"Wendy, thanks for signing up for Starbucks - please add Apple Pay!"},
          @"buttons" : @[@{@"id" : @"id1", @"text" : @"green"}, @{@"id" : @"id2", @"text" : @"red"}],
          @"data" : @{@"OpenURL" : @"https://www.arstechnica.com"}
        };
        
        [OneSignal postNotification:content onSuccess:^(NSDictionary *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textView.text = [NSString stringWithFormat:@"Successfully sent notification with payload: \n\n%@", content];
            });
        } onFailure:^(NSError *error) {
            [self displayError:error.localizedDescription];
        }];
    } else {
        [self displayError:@"Could not send push notification: current user does not have a push token"];
    }
}

- (IBAction)registerButtonPressed:(UIButton *)sender {
    OSPermissionSubscriptionState *state = [OneSignal getPermissionSubscriptionState];
    
    if (!state.permissionStatus.hasPrompted) {
        [OneSignal promptForPushNotificationsWithUserResponse:^(BOOL accepted) {
            NSLog(@"User %@ Notifications Permission", accepted ? @"Accepted" : @"Denied");
        }];
    } else {
        [self displaySettingsNotification];
    }
}

- (IBAction)subscriptionSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [OneSignal setSubscription:true];
    } else {
        [OneSignal setSubscription:false];
    }
}

- (IBAction)setEmailButtonPressed:(UIButton *)sender {
    [self.emailTextField resignFirstResponder];
    
    [self.setEmailActivityIndicatorView startAnimating];
    sender.hidden = true;
    
    [OneSignal setEmail:self.emailTextField.text withSuccess:^{
        [self.setEmailActivityIndicatorView stopAnimating];
        sender.hidden = false;
        
    } withFailure:^(NSError *error) {
        [self.setEmailActivityIndicatorView stopAnimating];
        sender.hidden = false;
        
        [self displayError:error.localizedDescription];
    }];
}

- (IBAction)logoutEmailButtonPressed:(UIButton *)sender {
    [self changeLoadingButtonAnimationStateWithTrailingConstraint:self.logoutEmailTrailingSpaceConstraint withActivityIndicatorView:self.logoutEmailActivityIndicatorView animatingState:true];
    
    [OneSignal logoutEmailWithSuccess:^{
        [self changeLoadingButtonAnimationStateWithTrailingConstraint:self.logoutEmailTrailingSpaceConstraint withActivityIndicatorView:self.logoutEmailActivityIndicatorView animatingState:false];
    } withFailure:^(NSError *error) {
        [self changeLoadingButtonAnimationStateWithTrailingConstraint:self.logoutEmailTrailingSpaceConstraint withActivityIndicatorView:self.logoutEmailActivityIndicatorView animatingState:false];
        
        [self displayError:error.localizedDescription];
    }];
}

#pragma mark UITextFieldDelegate Methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return true;
}

#pragma mark OSPermissionStateChanges Delegate Method
-(void)onOSPermissionChanged:(OSPermissionStateChanges *)stateChanges {
    if (stateChanges.from.status == OSNotificationPermissionNotDetermined) {
        if (stateChanges.to.status == OSNotificationPermissionAuthorized) {
            self.registerButton.backgroundColor = [UIColor greenColor];
            self.registerButton.userInteractionEnabled = false;
            self.subscriptionStatusSwitch.userInteractionEnabled = true;
            [InfluxDb sendToInfluxDBWithEvent:@"subscribed_true"];
        } else if (stateChanges.to.status == OSNotificationPermissionDenied) {
            [self displaySettingsNotification];
        }
    } else {
        self.registerButton.enabled = true;
        self.subscriptionStatusSwitch.userInteractionEnabled = false;
    }
}

#pragma mark OSSubscriptionStateChanges Delegate Method
-(void)onOSSubscriptionChanged:(OSSubscriptionStateChanges *)stateChanges {
    if (stateChanges.from.subscribed &&  !stateChanges.to.subscribed) {
        self.subscriptionStatusSwitch.on = false;
        self.subscriptionStatusLabel.text = @"Set Subscription OFF";
        self.registerButton.backgroundColor = [UIColor redColor];
        
        [InfluxDb sendToInfluxDBWithEvent:@"subscribed_false"];
    } else if (!stateChanges.from.subscribed && stateChanges.to.subscribed) {
        self.subscriptionStatusSwitch.on = true;
        self.subscriptionStatusLabel.text = @"Set Subscription ON";
        self.registerButton.backgroundColor = [UIColor greenColor];
        
        [InfluxDb sendToInfluxDBWithEvent:@"subscribed_true"];
    }
}

#pragma mark OSEmailSubscriptionStateChanges Delegate Method
-(void)onOSEmailSubscriptionChanged:(OSEmailSubscriptionStateChanges *)stateChanges {
    NSError *error;
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:stateChanges.toDictionary options:NSJSONWritingPrettyPrinted error:&error] encoding:NSUTF8StringEncoding];
    self.textView.text = jsonString;
}

@end
