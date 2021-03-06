//
//  ProfileHeaderView.h
//  newsyc
//
//  Created by Grant Paul on 3/5/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

@class HNUser;
@interface ProfileHeaderView : UIView {
    HNUser *user;
    UILabel *titleLabel;
    UILabel *subtitleLabel;

    CGFloat padding;
}

+ (CGFloat)defaultHeight;

@property (nonatomic, strong) HNUser *user;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

@property (nonatomic, assign) CGFloat padding;

@end
