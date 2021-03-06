//
//  MoreController.m
//  newsyc
//
//  Created by Grant Paul on 3/4/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import <HNKit/HNKit.h>

#import "MoreController.h"
#import "ProfileController.h"
#import "ProfileHeaderView.h"
#import "SubmissionListController.h"
#import "CommentListController.h"
#import "BrowserController.h"

#import "AppDelegate.h"

@implementation MoreController

- (id)initWithSession:(HNSession *)session_ {
    if ((self = [super init])) {
        session = session_;
    }

    return self;
}


- (void)loadView {
    [super loadView];
    
    tableView = [[OrangeTableView alloc] initWithFrame:[[self view] bounds]];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [[self view] addSubview:tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:@"More"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    /*if ([self respondsToSelector:@selector(topLayoutGuide)] && [self respondsToSelector:@selector(bottomLayoutGuide)]) {
        UIEdgeInsets insets = UIEdgeInsetsMake([[self topLayoutGuide] length], 0, [[self bottomLayoutGuide] length], 0);
        [tableView setScrollIndicatorInsets:insets];
        [tableView setContentInset:insets];
    }*/
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    tableView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [tableView setOrange:![[NSUserDefaults standardUserDefaults] boolForKey:@"disable-orange"]];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 3;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 4;
        case 1: return 2;
        case 2: return 3;
        default: return 0;
    }
}

- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Best Submissions"];
        } else if ([indexPath row] == 1) {
            [[cell textLabel] setText:@"Active Discussions"];
        } else if ([indexPath row] == 2) {
            [[cell textLabel] setText:@"Classic View"];
        } else if ([indexPath row] == 3) {
            [[cell textLabel] setText:@"Ask HN"];
        }
    } else if ([indexPath section] == 1) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Best Comments"];
        } else if ([indexPath row] == 1) {
            [[cell textLabel] setText:@"New Comments"];
        } 
    } else if ([indexPath section] == 2) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Hacker News FAQ"];
        } else if ([indexPath row] == 1) {
            [[cell textLabel] setText:@"news:yc homepage"];
        } else if ([indexPath row] == 2) {
            [[cell textLabel] setText:@"@newsyc_"];
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Submissions";
    } else if (section == 1) {
        return @"Comments";
    } else if (section == 2) {
        return @"Other";
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return [NSString stringWithFormat:@"news:yc version %@.\n\nIf you're having issues or have suggestions, feel free to email me: support@newsyc.me\n\nSettings are available in the Settings app.", [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];
    }
    
    return nil;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HNEntryListIdentifier type = nil;
    NSString *title = nil;
    Class controllerClass = nil;
    
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            type = kHNEntryListIdentifierBestSubmissions;
            title = @"Best Submissions";
            controllerClass = [SubmissionListController class];
        } else if ([indexPath row] == 1) {
            type = kHNEntryListIdentifierActiveSubmissions;
            title = @"Active";
            controllerClass = [SubmissionListController class];
        } else if ([indexPath row] == 2) {
            type = kHNEntryListIdentifierClassicSubmissions;
            title = @"Classic";
            controllerClass = [SubmissionListController class];
        } else if ([indexPath row] == 3) {
            type = kHNEntryListIdentifierAskSubmissions;
            title = @"Ask HN";
            controllerClass = [SubmissionListController class];
        }
    } else if ([indexPath section] == 1) {
        if ([indexPath row] == 0) {
            type = kHNEntryListIdentifierBestComments;
            title = @"Best Comments";
            controllerClass = [CommentListController class];
        } else if ([indexPath row] == 1) {
            type = kHNEntryListIdentifierNewComments;
            title = @"New Comments";
            controllerClass = [CommentListController class];
        }
    } else if ([indexPath section] == 2) {
        if ([indexPath row] == 0) {
            BrowserController *controller = [[BrowserController alloc] initWithURL:kHNFAQURL];
            [[self navigation] pushController:controller animated:YES];
            return;
        } else if ([indexPath row] == 1) {
            BrowserController *controller = [[BrowserController alloc] initWithURL:[NSURL URLWithString:@"http://newsyc.me/"]];
            [[self navigation] pushController:controller animated:YES];
            return;
        } else if ([indexPath row] == 2) {
            BrowserController *controller = [[BrowserController alloc] initWithURL:[NSURL URLWithString:@"https://twitter.com/newsyc_"]];
            [[self navigation] pushController:controller animated:YES];
            return;
        }
    }
    
    HNEntryList *list = [HNEntryList session:session entryListWithIdentifier:type];
    UIViewController *controller = [[controllerClass alloc] initWithSource:list];
    [controller setTitle:title];
    
    if (controllerClass == [SubmissionListController class]) {
        [[self navigation] pushController:controller animated:YES];
    } else {
        [[self navigation] pushController:controller animated:YES];
    }
}

AUTOROTATION_FOR_PAD_ONLY

@end
