//
//  LoadingController.h
//  newsyc
//
//  Created by Grant Paul on 3/4/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import <MessageUI/MFMailComposeViewController.h>

#import <HNKit/HNKit.h>

#import "LoginController.h"

#import "BarButtonItem.h"
#import "ActivityIndicatorItem.h"
#import "PlacardButton.h"

@class LoadingIndicatorView;
@interface LoadingController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    HNObject *source;
    
    UIView *statusView;
    NSMutableSet *statusViews;
    
    PlacardButton *retryButton;
    LoadingIndicatorView *indicator;

    NSDate *lastUpdatedOnAppearDate;
    
    BarButtonItem *actionItem;
    NSInteger openInSafariIndex;
    NSInteger mailLinkIndex;
    NSInteger copyLinkIndex;
    NSInteger readLaterIndex;
}

@property (nonatomic, strong) HNObject *source;

- (id)initWithSource:(HNObject *)source_;
- (NSString *)sourceTitle;
- (void)finishedLoading;

- (void)addStatusView:(UIView *)view;
- (void)removeStatusView:(UIView *)view;
- (void)updateStatusDisplay;

- (void)sourceStartedLoading;
- (void)sourceFinishedLoading;
- (void)sourceFailedLoading;

@end
