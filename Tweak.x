#import <UIKit/UIKit2.h>
#import <CaptainHook/CaptainHook.h>
#import <QuartzCore/QuartzCore.h>

#import "Headers.h"

typedef enum {
	DBBulletinStyleSmallBanner = 0,
	DBBulletinStyleLargeBanner = 1,
	DBBulletinStyleStatusBar = 2
} DBBulletinStyle;

static NSDictionary *settings;
static DBBulletinStyle currentStyle;
static BOOL enableSmartTitles;
static BOOL scrollToEnd;

static UIStatusBarStyle DBCurrentStatusBarStyle(void)
{
    SBApplication *activeApp = [(SpringBoard *)UIApp _accessibilityFrontMostApplication];
    return activeApp ? [activeApp statusBarStyle] : [UIApp statusBarStyle];
}

%config(generator=internal);

%hook SBBulletinBannerController

- (CGRect)_currentBannerFrameForOrientation:(UIInterfaceOrientation)orientation
{
	CGRect result = %orig();
	switch (currentStyle) {
		case DBBulletinStyleSmallBanner:
			result.size.height -= 18.0f;
			break;
		case DBBulletinStyleLargeBanner:
			break;
		case DBBulletinStyleStatusBar:
			result.size.height -= 20.0f;
			break;
	}
	return result;
}

%end

%hook SBBannerAndShadowView

- (void)setBannerFrame:(CGRect)frame
{
	switch (currentStyle) {
		case DBBulletinStyleSmallBanner:
			frame.size.height = 22.0f;
			break;
		case DBBulletinStyleLargeBanner:
			break;
		case DBBulletinStyleStatusBar:
			frame.size.height = 20.0f;
			break;
	}
	%orig();
}

- (CGRect)_frameForBannerFrame:(CGRect)bannerFrame
{
	CGRect result = %orig();
	switch (currentStyle) {
		case DBBulletinStyleSmallBanner:
			result.size.height -= 18.0f;
			break;
		case DBBulletinStyleLargeBanner:
			break;
		case DBBulletinStyleStatusBar:
			result.size.height -= 20.0f;
			break;
	}
	return result;
}

- (void)setShadowAlpha:(CGFloat)alpha
{
	switch (currentStyle) {
		case DBBulletinStyleSmallBanner:
			break;
		case DBBulletinStyleLargeBanner:
			break;
		case DBBulletinStyleStatusBar:
			alpha = 0.0f;
			break;
	}
	%orig();
}

%end

__attribute__((visibility("hidden")))
@interface DietBulletinMarqueeLabel : UILabel
@end

@implementation DietBulletinMarqueeLabel

- (void)_startMarquee
{
	[super _startMarquee];
	// Find the imageview subview that has the animation on it
	NSArray *subviews = [self subviews];
	if ([subviews count]) {
		CALayer *layer = [[subviews objectAtIndex:0] layer];
		NSArray *animationKeys = [layer animationKeys];
		if ([animationKeys count]) {
			// And suck out the animation's duration
			NSTimeInterval duration = [layer animationForKey:[animationKeys objectAtIndex:0]].duration;
			// Make the banner stay on screen at least that long
			if (duration > 2.5) {
				SBBulletinBannerController *bc = [%c(SBBulletinBannerController) sharedInstance];
				NSArray *modes = [[NSArray alloc] initWithObjects:NSRunLoopCommonModes, nil];
				[NSObject cancelPreviousPerformRequestsWithTarget:bc selector:@selector(_replaceIntervalElapsed) object:nil];
				[bc performSelector:@selector(_replaceIntervalElapsed) withObject:nil afterDelay:duration inModes:modes];
				if (duration > 6.5) {
					[NSObject cancelPreviousPerformRequestsWithTarget:bc selector:@selector(_dismissIntervalElapsed) object:nil];
					[bc performSelector:@selector(_dismissIntervalElapsed) withObject:nil afterDelay:duration inModes:modes];
				}
				[modes release];
			}
		}
	}
	// We've got all we need
	object_setClass(self, [UILabel class]);
}

@end

%hook SBBannerView

- (id)initWithItem:(id)item
{
	if ((self = %orig())) {
		switch (currentStyle) {
			case DBBulletinStyleSmallBanner: {
				[self setBackgroundColor:[UIColor whiteColor]];
				CALayer *layer = [self layer];
				[layer setCornerRadius:3.5f];
				[layer setContents:(id)[UIImage imageNamed:@"BannerGradientMiddle"].CGImage];
				break;
			}
			case DBBulletinStyleLargeBanner:
				break;
			case DBBulletinStyleStatusBar: {
				[self setBackgroundColor:[UIColor blackColor]];
				CALayer *layer = [self layer];
				UIImage *image = [UIImage kitImageNamed:DBCurrentStatusBarStyle() == UIStatusBarStyleDefault ? @"Silver_Base.png" : @"Black_Base.png"];
				layer.contents = (id)image.CGImage;
				layer.contentsCenter = (CGRect){ { 0.5f, 0.0f }, { 0.0f, 1.0f } };
				layer.contentsScale = image.scale;
				break;
			}
		}
	}
	return self;
}

- (UIImage *)_bannerImageWithAttachmentImage:(UIImage *)attachmentImage
{
	switch (currentStyle) {
		case DBBulletinStyleSmallBanner:
			return nil;
		case DBBulletinStyleLargeBanner:
			return %orig();
		case DBBulletinStyleStatusBar:
			return nil;
	}
	return nil;
}

static BOOL DBShouldShowTitleForDisplayIdentifier(NSString *displayIdentifier)
{
	NSString *key = [NSString stringWithFormat:@"DBShowTitle-%@", displayIdentifier];
	id value = [settings objectForKey:key];
	return !value || [value boolValue];
}

static inline void DBApplyMarqueeAndExtendedDelay(UILabel *label) {
	if ([UILabel instancesRespondToSelector:@selector(setMarqueeEnabled:)] && [UILabel instancesRespondToSelector:@selector(setMarqueeRunning:)]) {
		[label setMarqueeEnabled:YES];
		[label setMarqueeRunning:YES];
		// Swap classes so that we can determine how long the marquee will take
		if (scrollToEnd) {
			object_setClass(label, [DietBulletinMarqueeLabel class]);
		}
	}
}

- (void)layoutSubviews
{
	%orig();
	UIImageView **_iconView = CHIvarRef(self, _iconView, UIImageView *);
	UILabel **_titleLabel = CHIvarRef(self, _titleLabel, UILabel *);
	UILabel **_messageLabel = CHIvarRef(self, _messageLabel, UILabel *);
	UIView **_underlayView = CHIvarRef(self, _underlayView, UIView *);
	if (_iconView && _titleLabel && _messageLabel && _underlayView) {
		switch (currentStyle) {
			case DBBulletinStyleSmallBanner: {
				[*_iconView setFrame:(CGRect){ { 1.0f, 1.0f }, { 20.0f, 20.0f } }];
				CGRect bounds = [self bounds];
				if (DBShouldShowTitleForDisplayIdentifier(self.item.seedBulletin.sectionID)) {
					[*_titleLabel setHidden:NO];
					CGSize firstLabelSize = [*_titleLabel sizeThatFits:bounds.size];
					[*_titleLabel setFrame:(CGRect){ { 24.0f, 0.0f }, { firstLabelSize.width, 21.0f } }];
					[*_messageLabel setFrame:(CGRect){ { firstLabelSize.width + 28.0f, 1.5f }, { bounds.size.width - firstLabelSize.width - 30.0f, 21.0f } }];
				} else {
					[*_titleLabel setHidden:YES];
					[*_messageLabel setFrame:(CGRect){ { 24.0f, 1.5f }, { bounds.size.width - 26.0f, 21.0f } }];
				}
				[*_underlayView setHidden:YES];
				break;
			}
			case DBBulletinStyleLargeBanner:
				break;
			case DBBulletinStyleStatusBar: {
				NSString *sectionID = self.item.seedBulletin.sectionID;
				UIImage *largerImage = [UIImage _applicationIconImageForBundleIdentifier:sectionID format:0 scale:2.0];
				if (largerImage) {
					[*_iconView setImage:largerImage];
				}
				[*_iconView setFrame:(CGRect){ { 2.0f, 2.0f }, { 16.0f, 16.0f } }];
				[*_titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
				[*_messageLabel setFont:[UIFont systemFontOfSize:12]];
				if (DBCurrentStatusBarStyle() != UIStatusBarStyleDefault) {
					UIColor *white = [UIColor whiteColor];
					[*_titleLabel setTextColor:white];
					[*_messageLabel setTextColor:white];
				} else {
					UIColor *shadowColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
					[*_titleLabel setShadowColor:shadowColor];
					[*_titleLabel setShadowOffset:(CGSize){ 0.0f, 1.0f }];
					[*_messageLabel setShadowColor:shadowColor];
					[*_messageLabel setShadowOffset:(CGSize){ 0.0f, 1.0f }];
				}
				CGRect bounds = [self bounds];
				if (DBShouldShowTitleForDisplayIdentifier(sectionID)) {
					[*_titleLabel setHidden:NO];
					CGSize firstLabelSize = [*_titleLabel sizeThatFits:bounds.size];
					[*_titleLabel setFrame:(CGRect){ { 22.0f, 0.5f }, { firstLabelSize.width, 19.0f } }];
					[*_messageLabel setFrame:(CGRect){ { firstLabelSize.width + 26.0f, 0.5f }, { bounds.size.width - firstLabelSize.width - 28.0f, 19.0f } }];
				} else {
					[*_titleLabel setHidden:YES];
					[*_messageLabel setFrame:(CGRect){ { 22.0f, 0.5f }, { bounds.size.width - 24.0f, 19.0f } }];
				}
				[*_underlayView setHidden:YES];
				break;
			}
		}
		DBApplyMarqueeAndExtendedDelay(*_messageLabel);
	}
}

%end

static NSInteger suppressMessageOverride;
static NSMutableDictionary *textExtractors;

typedef struct {
	NSRange titleRange;
	NSRange messageRange;
} DBTextRanges;
typedef DBTextRanges (^DBTextExtractor)(NSString *message);

%hook SBBulletinBannerItem

- (NSString *)title
{
	if (!enableSmartTitles) {
		return %orig();
	}
	NSString *displayIdentifier = self.seedBulletin.sectionID;
	DBTextExtractor extractor = (DBTextExtractor)[textExtractors objectForKey:displayIdentifier];
	if (extractor) {
		if (DBShouldShowTitleForDisplayIdentifier(displayIdentifier)) {
			suppressMessageOverride++;
			NSString *message = self.message;
			suppressMessageOverride--;
			DBTextRanges result = extractor(message);
			if (result.titleRange.location != NSNotFound) {
				return [message substringWithRange:result.titleRange];
			}
		}
	}
	return %orig();
}

- (NSString *)message
{
	if (suppressMessageOverride || !enableSmartTitles) {
		return %orig();
	}
	NSString *displayIdentifier = self.seedBulletin.sectionID;
	DBTextExtractor extractor = (DBTextExtractor)[textExtractors objectForKey:displayIdentifier];
	if (extractor) {
		if (DBShouldShowTitleForDisplayIdentifier(displayIdentifier)) {
			NSString *message = %orig();
			DBTextRanges result = extractor(message);
			if (result.messageRange.location != NSNotFound) {
				return [message substringWithRange:result.messageRange];
			}
			return message;
		}
	}
	return %orig();
}

%end

static inline void DBRegisterTextExtractor(NSString *displayIdentifier, DBTextExtractor textExtractor)
{
	[textExtractors setObject:textExtractor forKey:displayIdentifier];
}

static inline DBTextRanges DBTextExtractUnchanged(NSString *message)
{
	return (DBTextRanges){ (NSRange){ NSNotFound, -1 }, (NSRange){ 0, [message length] } };
}

static inline DBTextRanges DBTextExtractAllAsTitle(NSString *message)
{
	return (DBTextRanges){ (NSRange){ 0, [message length] }, (NSRange){ 0, 0 } };
}

static inline DBTextRanges DBTextExtractSplitAround(NSString *message, NSInteger skipBefore, NSInteger continueInto, NSString *splitAround, NSInteger skipAfter, NSInteger skipEnd)
{
	NSInteger length = [message length];
	NSInteger location = [message rangeOfString:splitAround options:0 range:(NSRange) { skipBefore, length - skipBefore }].location;
	if (location != NSNotFound) {
		return (DBTextRanges){ (NSRange){ skipBefore, location - skipBefore + continueInto }, (NSRange){ location + skipAfter, length - location - skipAfter - skipEnd } };
	}
	return DBTextExtractUnchanged(message);
}

static BOOL characterAtIndexIsUpperCase(NSString *text, NSInteger index)
{
	NSString *justCharacter = [text substringWithRange:(NSRange){ index, 1 }];
	return ![justCharacter isEqualToString:[justCharacter lowercaseString]];
}

static inline DBTextRanges DBTextExtractLeadingCapitals(NSString *message)
{
	NSInteger length = [message length];
	NSInteger spaceLocation;
	NSRange remainingRange = (NSRange){ 0, length - 1 };
	while ((spaceLocation = [message rangeOfString:@" " options:0 range:remainingRange].location) != NSNotFound) {
		if (!characterAtIndexIsUpperCase(message, spaceLocation + 1)) {
			return (DBTextRanges){ (NSRange){ 0, spaceLocation }, (NSRange){ spaceLocation + 1, length - spaceLocation - 1} };
		}
		remainingRange.location = spaceLocation + 1;
		remainingRange.length = length - spaceLocation - 2;
	}
	return DBTextExtractUnchanged(message);
}

static void LoadSettings(void)
{
	[settings release];
	settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.rpetrich.dietbulletin.plist"];
	id temp;
	currentStyle = [[settings objectForKey:@"DBBulletinStyle"] intValue];
	temp = [settings objectForKey:@"DBEnableSmartTitles"];
	enableSmartTitles = temp ? [temp boolValue] : YES;
	temp = [settings objectForKey:@"DBScrollToEnd"];
	scrollToEnd = temp ? [temp boolValue] : YES;
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init();
	textExtractors = [[NSMutableDictionary alloc] init];
	LoadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (void *)LoadSettings, CFSTR("com.rpetrich.dietbulletin.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	// Tweetbot
	DBRegisterTextExtractor(@"com.tapbots.Tweetbot", ^(NSString *message){
		return DBTextExtractSplitAround(message, 0, 0, @" ", 1, 0);
	});
	// Instagram
	DBRegisterTextExtractor(@"com.burbn.instagram", ^(NSString *message){
		return DBTextExtractSplitAround(message, 0, 0, @" ", 1, 0);
	});
	// Foursquare
	DBRegisterTextExtractor(@"com.naveenium.foursquare", ^(NSString *message){
		return DBTextExtractSplitAround(message, 0, 1, @". ", 2, 0);
	});
	// Whatsapp
	DBRegisterTextExtractor(@"net.whatsapp.WhatsApp", ^(NSString *message){
		return DBTextExtractSplitAround(message, 0, 0, @": ", 2, 0);
	});
	// PayPal
	DBRegisterTextExtractor(@"com.yourcompany.PPClient", ^(NSString *message){
		if ([message hasPrefix:@"You received "]) {
			return DBTextExtractSplitAround(message, 13, 0, @" from ", 1, 0);
		}
		return DBTextExtractUnchanged(message);
	});
	// Skype
	DBRegisterTextExtractor(@"com.skype.skype", ^(NSString *message){
		if ([message hasPrefix:@"Call from "] || [message hasPrefix:@"Voicemail from "]) {
			return DBTextExtractAllAsTitle(message);
		}
		if ([message hasPrefix:@"New message from "]) {
			return DBTextExtractSplitAround(message, 17, 0, @": ", 2, 0);
		}
		return DBTextExtractUnchanged(message);
	});
	// BeejiveIM
	DBRegisterTextExtractor(@"com.beejive.BeejiveIM", ^(NSString *message){
		return DBTextExtractSplitAround(message, 0, 0, @": ", 2, 0);
	});
	// Trillian
	DBRegisterTextExtractor(@"com.ceruleanstudios.trillian.iphone", ^(NSString *message){
		return DBTextExtractSplitAround(message, 0, 0, @": ", 2, 0);
	});
	// Facebook
	DBRegisterTextExtractor(@"com.facebook.Facebook", ^(NSString *message){
		return DBTextExtractLeadingCapitals(message);
	});
	// Batch
	DBRegisterTextExtractor(@"com.batch.batch-iphone", ^(NSString *message){
		return DBTextExtractLeadingCapitals(message);
	});
	// Path
	DBRegisterTextExtractor(@"com.path.Path", ^(NSString *message){
		return DBTextExtractLeadingCapitals(message);
	});
	// Quora
	DBRegisterTextExtractor(@"com.quora.app.mobile", ^(NSString *message){
		return DBTextExtractLeadingCapitals(message);
	});
	[pool drain];
}
