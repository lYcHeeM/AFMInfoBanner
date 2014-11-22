//
//  CVKInfoBanner.m
//  CVKInfoBanner
//
//  Created by Romans Karpelcevs on 6/14/13.
//  Copyright (c) 2013 Romans Karpelcevs. All rights reserved.
//

#import <CVKHierarchySearcher/CVKHierarchySearcher.h>
#import "CVKInfoBanner.h"

#ifdef UIColorFromRGB
    #undef UIColorFromRGB
#endif

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((((rgbValue) & 0xFF0000) >> 16))/255.f \
                                                 green:((((rgbValue) & 0xFF00) >> 8))/255.f \
                                                  blue:(((rgbValue) & 0xFF))/255.f alpha:1.0]

static const CGFloat kMargin = 10.f;
static const NSTimeInterval kAnimationDuration = 0.3;
static const int kRedBannerColor = 0xff0000;
static const int kGreenBannerColor = 0x008000;
static const int kDefaultTextColor = 0xffffff;
static const CGFloat kFontSize = 13.f;
static const CGFloat kDefaultHideInterval = 2.0;

@interface CVKInfoBanner ()

@property (nonatomic) UILabel *textLabel;
@property (nonatomic) UIView *targetView;
@property (nonatomic) UIView *viewAboveBanner;
@property (nonatomic) CGFloat additionalTopSpacing;
@property (nonatomic) NSLayoutConstraint *topSpacingConstraint;

@end

@implementation CVKInfoBanner

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setStyle:(CVKInfoBannerStyle)style
{
    _style = style;
    [self applyStyle];
}

- (void)applyStyle
{
    if (self.style == CVKInfoBannerStyleRed) {
        [self setBackgroundColor:self.errorBackgroundColor];
        [self.textLabel setTextColor:self.errorTextColor];
    } else if (self.style == CVKInfoBannerStyleGreen) {
        [self setBackgroundColor:self.infoBackgroundColor];
        [self.textLabel setTextColor:self.infoTextColor];
    }
}

- (void)setText:(NSString *)text
{
    _text = text;
    [self.textLabel setText:text];
    [self setNeedsLayout];
}

- (void)setErrorBackgroundColor:(UIColor *)errorBackgroundColor
{
    _errorBackgroundColor = errorBackgroundColor;
    [self applyStyle];
}

- (void)setInfoBackgroundColor:(UIColor *)infoBackgroundColor
{
    _infoBackgroundColor = infoBackgroundColor;
    [self applyStyle];
}

- (void)setErrorTextColor:(UIColor *)errorTextColor
{
    _errorTextColor = errorTextColor;
    [self applyStyle];
}

- (void)setInfoTextColor:(UIColor *)infoTextColor
{
    _infoTextColor = infoTextColor;
    [self applyStyle];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self.textLabel setFont:font];
}

- (void)setUp
{
    _font = [UIFont boldSystemFontOfSize:kFontSize];
    _errorBackgroundColor = UIColorFromRGB(kRedBannerColor);
    _infoBackgroundColor = UIColorFromRGB(kGreenBannerColor);
    _errorTextColor = UIColorFromRGB(kDefaultTextColor);
    _infoTextColor = UIColorFromRGB(kDefaultTextColor);

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:self.errorBackgroundColor];

    UILabel *label = [[UILabel alloc] init];
    [self setTextLabel:label];
    [self configureLabel];
    [self addSubview:label];
}

- (void)configureLabel
{
    [self.textLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    [self.textLabel setTextColor:self.errorTextColor];

    [self.textLabel setTextAlignment:NSTextAlignmentCenter];
    [self.textLabel setFont:self.font];
    [self.textLabel setNumberOfLines:0];
}

- (void)updateConstraints
{
    NSDictionary *viewsDict = @{@"self": self, @"label": self.textLabel};

    // Expand to the superview's width
    [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[self]|"
                                                                           options:0 metrics:nil views:viewsDict]];
    // Place initial constraint exactly one frame above the bottom line of view above us
    // or above top of screen, if there is no such view. Assign it to property to animate later.
    CGFloat topOffset = -self.frame.size.height;
    if (self.viewAboveBanner)
        topOffset += CGRectGetMaxY(self.viewAboveBanner.frame);
    NSArray *topConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(offset)-[self]"
                                                                      options:0
                                                                      metrics:@{@"offset": @(topOffset)}
                                                                        views:viewsDict];
    self.topSpacingConstraint = [topConstraints firstObject];
    [self.superview addConstraints:topConstraints];

    // Position label correctly
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[label]-|"
                                                                 options:0 metrics:nil views:viewsDict]];
    CGFloat topMargin = kMargin + self.additionalTopSpacing;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[label]-(bottom)-|"
                                                                 options:0
                                                                 metrics:@{@"top": @(topMargin), @"bottom": @(kMargin)}
                                                                   views:viewsDict]];
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
    [super layoutSubviews];
}

- (void)show
{
    [self show:YES];
}

- (void)show:(BOOL)animated
{
    [self setupViewsAndFrames];

    // In previously indicated, send subview to be below another view.
    // This is used when showing below navigation bar
    if (self.viewAboveBanner)
        [self.targetView insertSubview:self belowSubview:self.viewAboveBanner];
    else
        [self.targetView addSubview:self];

    [self setHidden:NO];

    if (animated) {
        // First pass calculates the height correctly with existing constraints.
        // Self-only doesn't calculate height on iOS 6, so pass through a superview
        [self updateConstraintsIfNeeded];
        [self.superview layoutIfNeeded];

        // Invalidate the top contraint because it needs to be changed
        [self.superview removeConstraint:self.topSpacingConstraint];

        // New pass to take frame and new top constraint, position frame before the animation
        [self setNeedsUpdateConstraints];
        [self.superview layoutIfNeeded];

        // Target top layout after animation is one frame down
        self.topSpacingConstraint.constant += self.frame.size.height;
        [UIView animateWithDuration:kAnimationDuration animations:^{
            [self.superview layoutIfNeeded];
        }];
    } else {
        self.topSpacingConstraint.constant += self.frame.size.height;
    }
}


- (void)setupViewsAndFrames
{
    UINavigationController *navVC = [[[CVKHierarchySearcher alloc] init] topmostNavigationController];
    if (navVC && navVC.navigationBar.superview) {
        self.targetView = navVC.navigationBar.superview;
        self.viewAboveBanner = navVC.navigationBar;
    } else {
        // If there isn't a navigation controller with a bar, show in window instead.
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        // Forget the frame convertions, smallest is the height, no doubt
        CGFloat statusBarHeight = MIN(statusBarFrame.size.width, statusBarFrame.size.height);

        self.additionalTopSpacing = statusBarHeight;
        self.targetView = window;
    }
}

- (void)hide
{
    [self hide:YES];
}

- (void)hide:(BOOL)animated
{
    if (animated) {
        self.topSpacingConstraint.constant -= self.frame.size.height;
        [UIView animateWithDuration:kAnimationDuration animations:^{
            [self.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

+ (instancetype)showAndHideWithText:(NSString *)text
                              style:(CVKInfoBannerStyle)style
{
    return [self showWithText:text style:style andHideAfter:kDefaultHideInterval];
}

+ (instancetype)showWithText:(NSString *)text
                       style:(CVKInfoBannerStyle)style
                andHideAfter:(NSTimeInterval)timeout
{
    CVKInfoBanner *banner = [self showWithText:text style:style];
    [banner performSelector:@selector(hide) withObject:nil afterDelay:timeout];
    return banner;
}

+ (instancetype)showWithText:(NSString *)text
                       style:(CVKInfoBannerStyle)style
{
    CVKInfoBanner *banner = [[[self class] alloc] init];
    [banner setText:text];
    [banner setStyle:style];

    [banner show];
    return banner;
}

+ (void)hideAll
{
    UINavigationController *navVC = [[[CVKHierarchySearcher alloc] init] topmostNavigationController];
    [self hideAllInView:navVC.navigationBar.superview];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [self hideAllInView:window];
}

+ (void)hideAllInView:(UIView *)view
{
    for (CVKInfoBanner *subview in view.subviews) {
        if ([subview isKindOfClass:[self class]]) {
            [subview hide:NO];
        }
    }
}

@end
