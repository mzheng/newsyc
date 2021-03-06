//
//  CommentListController.m
//  newsyc
//
//  Created by Grant Paul on 3/5/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <HNKit/HNKit.h>

#import "UIActionSheet+Context.h"
#import "UINavigationItem+MultipleItems.h"
#import "EmptyView.h"

#import "CommentListController.h"
#import "CommentTableCell.h"
#import "DetailsHeaderView.h"
#import "EntryActionsView.h"
#import "ProfileController.h"
#import "NavigationController.h"
#import "EntryReplyComposeController.h"
#import "BrowserController.h"
#import "HackerNewsLoginController.h"

#import "AppDelegate.h"
#import "ModalNavigationController.h"

@interface CommentListController ()

- (void)setupHeader;
- (void)clearSavedAction;
- (void)clearSavedCompletion;

@end

@implementation CommentListController

#pragma mark - Lifecycle

- (void)finishedLoading {
    [self setupHeader];
    
    [super finishedLoading];
}

- (void)loadView {
    [super loadView];

    [[self view] setBackgroundColor:[UIColor whiteColor]];
    [[self view] setClipsToBounds:YES];
    
    [emptyView setText:@"No Comments"];
    [statusView setBackgroundColor:[UIColor clearColor]];
    
    [self setupHeader];
    
    if ([source isKindOfClass:[HNEntry class]]) {
        entryActionsView = [[EntryActionsView alloc] initWithFrame:CGRectZero];
        [entryActionsView sizeToFit];
        
        [entryActionsView setDelegate:self];
        [entryActionsView setEntry:(HNEntry *) source];
        [entryActionsView setEnabled:[(HNEntry *) source isComment] forItem:kEntryActionsViewItemDownvote];
        [[self view] addSubview:entryActionsView];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [entryActionsView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];

            CGRect actionsFrame = [entryActionsView frame];
            actionsFrame.origin.y = [[self view] frame].size.height - actionsFrame.size.height;
            actionsFrame.size.width = [[self view] frame].size.width;
            [entryActionsView setFrame:actionsFrame];

            CGRect tableFrame = [tableView frame];
            tableFrame.size.height = [[self view] bounds].size.height - actionsFrame.size.height;
            [tableView setFrame:tableFrame];
        } else {
            CGRect actionsFrame = [entryActionsView frame];
            actionsFrame.size.width = 280.0f;
            [entryActionsView setFrame:actionsFrame];
        }
    }

    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [tableView setSeparatorColor:[UIColor whiteColor]];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[self navigationItem] removeRightBarButtonItem:entryActionsViewItem];
    }
    
    expandedCell = nil;
    entryActionsView = nil;
    entryActionsViewItem = nil;
    detailsHeaderView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([source isKindOfClass:[HNEntry class]]) {
        if ([(HNEntry *) source isSubmission]) [self setTitle:@"Submission"];
        if ([(HNEntry *) source isComment]) [self setTitle:@"Replies"];
    } else {
        [self setTitle:@"Comments"];
    }
        
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        entryActionsViewItem = [[BarButtonItem alloc] initWithCustomView:entryActionsView];
        [[self navigationItem] addRightBarButtonItem:entryActionsViewItem atPosition:UINavigationItemPositionLeft];
        [[self navigationItem] setTitle:nil];
    }
    
    // reload here so the code below has access to the loaded table cells
    // to properly re-expand the saved expanded cell from before the unload
    [tableView reloadData];
    
    // retore expanded cell after memory warning
    if (expandedEntry != nil) {
        NSIndexPath *indexPath = [self indexPathOfEntry:expandedEntry];
        
        if (indexPath != nil) {
            // expand the old expanded cell
            CommentTableCell *cell = (CommentTableCell *) [tableView cellForRowAtIndexPath:indexPath];
            [self setExpandedEntry:expandedEntry cell:cell];
        } else {
            // could not find entry, maybe it disappeared
            expandedEntry = nil;
            expandedCell = nil;
        }
    }

    [tableView setSeparatorColor:[UIColor whiteColor]];
    
    collapsedEntries = [NSMutableSet set];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"disable-orange"]) {
            [entryActionsView setStyle:kEntryActionsViewStyleOrange];
        } else {
            [entryActionsView setStyle:kEntryActionsViewStyleDefault];
        }
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"disable-orange"]) {
            [entryActionsView setStyle:kEntryActionsViewStyleTransparentLight];
        } else {
            [entryActionsView setStyle:kEntryActionsViewStyleTransparentDark];
        }
    }

    [tableView setSeparatorColor:[UIColor whiteColor]];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self setupHeader];
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)dealloc {
    [self clearSavedAction];
    [self clearSavedCompletion];
    

}

#pragma mark - Table Cells

- (void)addChildrenOfEntry:(HNEntry *)entry toEntryArray:(NSMutableArray *)array includeChildren:(BOOL)includeChildren {
    // only show children of comments that are fully loaded
    includeChildren = includeChildren && [entry isLoaded] && [entry isKindOfClass:[HNEntry class]];
    
    for (HNEntry *child in [entry entries]) {
        [array addObject:child];
        
        if (includeChildren) {
            [self addChildrenOfEntry:child toEntryArray:array includeChildren:includeChildren];
        }
    }
}

- (void)loadEntries {
    NSMutableArray *children = [NSMutableArray array];
    [self addChildrenOfEntry:(HNEntry *) source toEntryArray:children includeChildren:YES]; 
    
    NSMutableArray *collapsedChildren = [NSMutableArray array];
    for (HNEntry *collapsedParent in collapsedEntries)
    {
        [self addChildrenOfEntry:collapsedParent
                    toEntryArray:collapsedChildren
                 includeChildren:YES];
    }
    [children removeObjectsInArray:collapsedChildren];
    entries = [children copy];
}

// XXX: this is really really slow :(
- (NSInteger)depthOfEntry:(HNEntry *)entry {
    NSInteger depth = 0;
    
    HNEntry *parent = [entry parent];
    
    // parent can be nil if we the parent is unknown. this is usually because it
    // is a child of an entry list, not of an entry itself, so we don't know.
    if (parent == nil) return 0;
    
    while (parent != source && parent != nil) {
        depth += 1;
        parent = [parent parent];
    }
    
    // don't show it at some crazy indentation level if this happens
    if (parent == nil) return 0;
    
    return depth;
}

- (CGFloat)cellHeightForEntry:(HNEntry *)entry {
    CGFloat height = [CommentTableCell heightForEntry:entry
                                            withWidth:[[self view] bounds].size.width
                                             expanded:(entry == expandedEntry)
                                             showBody:![collapsedEntries containsObject:entry]
                                     indentationLevel:[self depthOfEntry:entry]];

    return height;
}

+ (Class)cellClass {
    return [CommentTableCell class];
}

- (void)configureCell:(CommentTableCell *)cell forEntry:(HNEntry *)entry {
    [cell setDelegate:self];
    [cell setClipsToBounds:YES];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setIndentationLevel:[self depthOfEntry:entry]];
    [cell setComment:entry];
    [cell setExpanded:(entry == expandedEntry)];
    [cell setCollapsedChildren:[collapsedEntries containsObject:entry]];
}

- (void)setExpandedEntry:(HNEntry *)entry cell:(CommentTableCell *)cell {
    [tableView beginUpdates];
    [expandedCell setExpanded:NO];
    expandedEntry = entry;
    expandedCell = cell;
    [expandedCell setExpanded:YES];
    [tableView endUpdates];
}

- (void)hideChildrenOfEntry:(HNEntry *)entry
{
    NSMutableArray *childrenOfEntry = [NSMutableArray array];
    [self addChildrenOfEntry:entry toEntryArray:childrenOfEntry includeChildren:YES];
    NSMutableArray *newEntries = [NSMutableArray arrayWithArray:entries];
    [newEntries removeObjectsInArray:childrenOfEntry];
    entries = newEntries;
    [tableView reloadData];
}

- (void)showChildrenOfEntry:(HNEntry *)entry
{
    NSMutableArray *childrenOfEntry = [NSMutableArray array];
    [self addChildrenOfEntry:entry toEntryArray:childrenOfEntry includeChildren:YES];
    NSMutableArray *newEntries = [NSMutableArray arrayWithArray:entries];
    NSUInteger parentIndex = [entries indexOfObject:entry];
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(parentIndex + 1, childrenOfEntry.count)];
    [newEntries insertObjects:childrenOfEntry atIndexes:indexes];
    entries = newEntries;
    [tableView reloadData];
}
#pragma mark - View Layout

- (void)addStatusView:(UIView *)view {
    CGRect statusFrame = [statusView frame];
    statusFrame.size.height = [tableView bounds].size.height - suggestedHeaderHeight;
    if (statusFrame.size.height < 64.0f) statusFrame.size.height = 64.0f;    
    [statusView setFrame:statusFrame];
    
    if (view != nil) {
        [tableView setTableFooterView:statusView];
    }
    
    [super addStatusView:view];
}

- (void)removeStatusView:(UIView *)view {
    [super removeStatusView:view];
    
    if ([statusViews count] == 0) {
        [statusView setFrame:CGRectZero];
        [tableView setTableFooterView:statusView];
    }
}

- (void)setupHeader {
    if (![self isViewLoaded]) return;

    // Only show it if the source is at least partially loaded.
    if (![source isKindOfClass:[HNEntry class]] || [(HNEntry *) source submitter] == nil) return;
    
    [pullToRefreshView setBackgroundColor:[UIColor whiteColor]];
    [pullToRefreshView setTextShadowColor:[UIColor whiteColor]];
    
    detailsHeaderView = nil;
    
    detailsHeaderView = [[DetailsHeaderView alloc] initWithEntry:(HNEntry *) source widthWidth:[[self view] bounds].size.width];
    [detailsHeaderView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin];
    [detailsHeaderView setDelegate:self];
    [tableView setTableHeaderView:detailsHeaderView];
    
    suggestedHeaderHeight = [detailsHeaderView bounds].size.height;
}

#pragma mark - Delegates

- (void)detailsHeaderView:(DetailsHeaderView *)header selectedURL:(NSURL *)url {
    BrowserController *controller = [[BrowserController alloc] initWithURL:url];
    [[self navigation] pushController:controller animated:YES];
}

- (void)commentTableCell:(CommentTableCell *)cell selectedURL:(NSURL *)url {
    BrowserController *controller = [[BrowserController alloc] initWithURL:url];
    [[self navigation] pushController:controller animated:YES];
}

- (void)commentTableCellTapped:(CommentTableCell *)cell {
    if (expandedEntry != [cell comment]) {
        [self setExpandedEntry:[cell comment] cell:cell];
    } else {
        [self setExpandedEntry:nil cell:nil];
    }
}

- (void)commentTableCellTappedUser:(CommentTableCell *)cell {
    [self showProfileForEntry:[cell comment]];
}

- (void)commentTableCellTappedExpander:(CommentTableCell *)cell {
    if (cell.collapsedChildren)
    {
        [collapsedEntries removeObject:[cell comment]];
        cell.collapsedChildren = !cell.collapsedChildren;
        [self showChildrenOfEntry:[cell comment]];
    }
    else
    {
        [collapsedEntries addObject:[cell comment]];
        cell.collapsedChildren = !cell.collapsedChildren;
        [self hideChildrenOfEntry:[cell comment]];
    }
}

- (void)commentTableCellDoubleTapped:(CommentTableCell *)cell {
    HNEntry *entry = [self entryAtIndexPath:[tableView indexPathForCell:cell]];
    CommentListController *controller = [[CommentListController alloc] initWithSource:entry];
    [[self navigation] pushController:controller animated:YES];
}

#pragma mark - Actions

- (void)flagFailed {
    UIAlertView *alert = [[UIAlertView alloc] init];
    [alert setTitle:@"Error Flagging"];
    [alert setMessage:@"Unable to submit your vote. Make sure you can flag items and haven't already."];
    [alert addButtonWithTitle:@"Continue"];
    [alert show];
}

- (void)voteFailed {
    UIAlertView *alert = [[UIAlertView alloc] init];
    [alert setTitle:@"Error Voting"];
    [alert setMessage:@"Unable to submit your vote. Make sure you can vote and haven't already."];
    [alert addButtonWithTitle:@"Continue"];
    [alert show];
}

- (void)performUpvoteForEntry:(HNEntry *)entry fromEntryActionsView:(EntryActionsView *)eav {
    HNSubmission *submission = [[HNSubmission alloc] initWithSubmissionType:kHNSubmissionTypeVote];
    [submission setDirection:kHNVoteDirectionUp];
    [submission setTarget:entry];
    
    __weak id successToken = nil;
    successToken = [[NSNotificationCenter defaultCenter] addObserverForName:kHNSubmissionSuccessNotification object:submission queue:nil usingBlock:^(NSNotification *block) {
        [entry beginLoading];
        [eav stopLoadingItem:kEntryActionsViewItemUpvote];
        
        [[NSNotificationCenter defaultCenter] removeObserver:successToken];        
    }];
    
    __weak id failureToken = nil;
    failureToken = [[NSNotificationCenter defaultCenter] addObserverForName:kHNSubmissionFailureNotification object:submission queue:nil usingBlock:^(NSNotification *block) {
        [self voteFailed];
        [eav stopLoadingItem:kEntryActionsViewItemUpvote];
        
        [[NSNotificationCenter defaultCenter] removeObserver:failureToken];
    }];
    
    [[source session] performSubmission:submission];

    [eav beginLoadingItem:kEntryActionsViewItemUpvote];
}

- (void)performDownvoteForEntry:(HNEntry *)entry fromEntryActionsView:(EntryActionsView *)eav {
    HNSubmission *submission = [[HNSubmission alloc] initWithSubmissionType:kHNSubmissionTypeVote];
    [submission setDirection:kHNVoteDirectionDown];
    [submission setTarget:entry];
    
    __weak id successToken = nil;
    successToken = [[NSNotificationCenter defaultCenter] addObserverForName:kHNSubmissionSuccessNotification object:submission queue:nil usingBlock:^(NSNotification *block) {
        [entry beginLoading];
        [eav stopLoadingItem:kEntryActionsViewItemDownvote];
        
        [[NSNotificationCenter defaultCenter] removeObserver:successToken];        
    }];
                                             
    __weak id failureToken = nil;
    failureToken = [[NSNotificationCenter defaultCenter] addObserverForName:kHNSubmissionFailureNotification object:submission queue:nil usingBlock:^(NSNotification *block) {
        [self voteFailed];
        [eav stopLoadingItem:kEntryActionsViewItemDownvote];
        
        [[NSNotificationCenter defaultCenter] removeObserver:failureToken];
    }];
    
    [[source session] performSubmission:submission];
    
    [eav beginLoadingItem:kEntryActionsViewItemDownvote];
}

- (void)performFlagForEntry:(HNEntry *)entry fromEntryActionsView:(EntryActionsView *)eav {
    HNSubmission *submission = [[HNSubmission alloc] initWithSubmissionType:kHNSubmissionTypeFlag];
    [submission setTarget:entry];
    
    __weak id successToken = nil;
    successToken = [[NSNotificationCenter defaultCenter] addObserverForName:kHNSubmissionSuccessNotification object:submission queue:nil usingBlock:^(NSNotification *block) {
        [entry beginLoading];
        [eav stopLoadingItem:kEntryActionsViewItemFlag];
        
        [[NSNotificationCenter defaultCenter] removeObserver:successToken];        
    }];
    
    __weak id failureToken = nil;
    failureToken = [[NSNotificationCenter defaultCenter] addObserverForName:kHNSubmissionFailureNotification object:submission queue:nil usingBlock:^(NSNotification *block) {
        [self flagFailed];
        [eav stopLoadingItem:kEntryActionsViewItemFlag];
        
        [[NSNotificationCenter defaultCenter] removeObserver:failureToken];
    }];
    
    [[source session] performSubmission:submission];

    
    [eav beginLoadingItem:kEntryActionsViewItemFlag];
}

- (void)showProfileForEntry:(HNEntry *)entry {
    ProfileController *controller = [[ProfileController alloc] initWithSource:[entry submitter]];
    [controller setTitle:@"Profile"];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [[self navigation] pushController:controller animated:YES];
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        ModalNavigationController *navigation = [[ModalNavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:navigation animated:YES completion:NULL];
    }
}

- (void)composeControllerDidCancel:(EntryReplyComposeController *)controller {
    return;
}

- (void)composeControllerDidSubmit:(EntryReplyComposeController *)controller {
    [[controller entry] beginLoading];
}

- (void)clearSavedCompletion {
    savedCompletion = nil;
}

- (void)clearSavedAction {
    savedAction = nil;
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)index {
    if ([[sheet sheetContext] isEqual:@"entry-action"]) {
        if (index != [sheet cancelButtonIndex]) {
            // The 2 is subtracted to cancel out the cancel button, and then
            // to account for the zero-indexed buttons, but the count from one.
            savedCompletion((int)([sheet numberOfButtons] - 1 - index - 1));
        } else {
            [self clearSavedCompletion];
        }
    } else {
        if ([[[self class] superclass] instancesRespondToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
            [super actionSheet:sheet clickedButtonAtIndex:index];
        }
    }
}

- (void)loginControllerDidLogin:(LoginController *)controller {
    [self dismissViewControllerAnimated:YES completion:^{
        savedAction();
    }];
}

- (void)loginControllerDidCancel:(LoginController *)controller {
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    [self clearSavedAction];
    [self clearSavedCompletion];
}

- (void)entryActionsView:(EntryActionsView *)eav didSelectItem:(EntryActionsViewItem)item {
    HNEntry *entry = [eav entry];
    
    __weak __typeof__(self) this = self;
    
    savedCompletion = [^(NSInteger index) {
        if (item == kEntryActionsViewItemReply) {
            EntryReplyComposeController *compose = [[EntryReplyComposeController alloc] initWithEntry:entry];
            [compose setDelegate:this];
            
            NavigationController *navigation = [[NavigationController alloc] initWithRootViewController:compose];
            [[this navigationController] presentViewController:navigation animated:YES completion:NULL];
        } else if (item == kEntryActionsViewItemUpvote) {
            [this performUpvoteForEntry:entry fromEntryActionsView:eav];
        } else if (item == kEntryActionsViewItemFlag) {
            [this performFlagForEntry:entry fromEntryActionsView:eav];
        } else if (item == kEntryActionsViewItemDownvote) {
            [this performDownvoteForEntry:entry fromEntryActionsView:eav];            
        } else if (item == kEntryActionsViewItemActions) {
            if (index == 0) {
                [this showProfileForEntry:entry];
            } else if (index == 1) {
                CommentListController *controller = [[CommentListController alloc] initWithSource:[entry parent]];
                [[this navigationController] pushController:controller animated:YES];
            } else if (index == 2) {
                CommentListController *controller = [[CommentListController alloc] initWithSource:[entry submission]];
                [[this navigationController] pushController:controller animated:YES];
            }
        }
        
        [this clearSavedCompletion];
    } copy];
    
    
    savedAction = [^{
        __strong typeof(self) strongSelf = this;
        if (item == kEntryActionsViewItemUpvote || item == kEntryActionsViewItemDownvote) {
            NSNumber *confirm = [[NSUserDefaults standardUserDefaults] objectForKey:@"interface-confirm-votes"];
            
            if (confirm != nil && [confirm boolValue]) {
                UIActionSheet *sheet = [[UIActionSheet alloc] init];
                [sheet addButtonWithTitle:@"Vote"];
                [sheet addButtonWithTitle:@"Cancel"];
                [sheet setCancelButtonIndex:1];
                [sheet setDelegate:this];
                [sheet setSheetContext:@"entry-action"];
                
                [sheet showFromBarButtonItemInWindow:[eav barButtonItemForItem:item] animated:YES];
            } else {
                strongSelf->savedCompletion(0);
            }
        } else if (item == kEntryActionsViewItemFlag) {
            UIActionSheet *sheet = [[UIActionSheet alloc] init];
            [sheet addButtonWithTitle:@"Flag"];
            [sheet addButtonWithTitle:@"Cancel"];
            [sheet setDestructiveButtonIndex:0];
            [sheet setCancelButtonIndex:1];
            [sheet setDelegate:this];
            [sheet setSheetContext:@"entry-action"];
            
            [sheet showFromBarButtonItemInWindow:[eav barButtonItemForItem:item] animated:YES];
        } else if (item == kEntryActionsViewItemActions) {
            UIActionSheet *sheet = [[UIActionSheet alloc] init];
            if ([entry submission]) [sheet addButtonWithTitle:@"Submission"];
            if ([entry parent]) [sheet addButtonWithTitle:@"Parent"];
            [sheet addButtonWithTitle:@"Submitter"];
            [sheet addButtonWithTitle:@"Cancel"];
            [sheet setCancelButtonIndex:([sheet numberOfButtons] - 1)];
            [sheet setDelegate:this];
            [sheet setSheetContext:@"entry-action"];
            
            [sheet showFromBarButtonItemInWindow:[eav barButtonItemForItem:item] animated:YES];
        } else if (item == kEntryActionsViewItemReply) {
            strongSelf->savedCompletion(0);
        }
        
        [this clearSavedAction];
    } copy];
    
    if (![[source session] isAnonymous] || item == kEntryActionsViewItemActions) {
        savedAction();
    } else {
        [[self navigation] requestLogin];
    }
}

- (NSString *)sourceTitle {
    if ([source isKindOfClass:[HNEntry class]]) {
        if ([(HNEntry *) source isSubmission]) {
            NSString *title = [(HNEntry *) source title];
            return title;
        } else {
            NSString *name = [[(HNEntry *) source submitter] identifier];
            return [NSString stringWithFormat:@"Comment by %@", name];
        }
    } else {
        return [self title];
    }

}

AUTOROTATION_FOR_PAD_ONLY

@end
