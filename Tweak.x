#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>
#import <QuartzCore/QuartzCore.h>

@interface UILabel (Marquee)
- (void)setMarqueeEnabled:(BOOL)marqueeEnabled;
- (void)setMarqueeRunning:(BOOL)marqueeRunning;
@end

%config(generator=internal);

%hook SBBulletinBannerController

- (CGRect)_currentBannerFrameForOrientation:(int)orientation
{
	CGRect result = %orig();
	result.size.height -= 18.0f;
	return result;
}

%end

%hook SBBannerAndShadowView

- (void)setBannerFrame:(CGRect)frame
{
	frame.size.height = 22.0f;
	%orig();
}

- (CGRect)_frameForBannerFrame:(CGRect)bannerFrame
{
	CGRect result = %orig();
	result.size.height -= 18.0f;
	return result;
}

%end

%hook SBBannerView

- (id)initWithItem:(id)item
{
	if ((self = %orig())) {
		[self setBackgroundColor:[UIColor whiteColor]];
		CALayer *layer = [self layer];
		[layer setCornerRadius:3.5f];
		[layer setContents:(id)[UIImage imageNamed:@"BannerGradientMiddle"].CGImage];
	}
	return self;
}

- (UIImage *)_bannerImageWithAttachmentImage:(UIImage *)attachmentImage
{
	return nil;
}

- (void)layoutSubviews
{
	%orig();
	UIImageView **_iconView = CHIvarRef(self, _iconView, UIImageView *);
	UILabel **_titleLabel = CHIvarRef(self, _titleLabel, UILabel *);
	UILabel **_messageLabel = CHIvarRef(self, _messageLabel, UILabel *);
	UIView **_underlayView = CHIvarRef(self, _underlayView, UIView *);
	if (_iconView && _titleLabel && _messageLabel && _underlayView) {
		[*_iconView setFrame:(CGRect){ { 1.0f, 1.0f }, { 20.0f, 20.0f, } }];
		CGRect bounds = [self bounds];
		CGSize firstLabelSize = [*_titleLabel sizeThatFits:bounds.size];
		[*_titleLabel setFrame:(CGRect){ { 24.0f, 0.0f }, { firstLabelSize.width, 21.0f } }];
		[*_messageLabel setFrame:(CGRect){ { firstLabelSize.width + 28.0f, 1.5f }, { bounds.size.width - firstLabelSize.width - 30.0f, 21.0f } }];
		if ([UILabel instancesRespondToSelector:@selector(setMarqueeEnabled:)] && [UILabel instancesRespondToSelector:@selector(setMarqueeRunning:)]) {
			[*_messageLabel setMarqueeEnabled:YES];
			[*_messageLabel setMarqueeRunning:YES];
		}
		[*_underlayView setHidden:YES];
	}
}

%end
