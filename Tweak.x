#import <UIKit/UIKit2.h>
#import <CaptainHook/CaptainHook.h>
#import <QuartzCore/QuartzCore.h>
#import <SpringBoard/SpringBoard.h>

@class BBAction, BBObserver, BBAssertion, BBAttachments, BBSound, BBContent;

@interface BBBulletin : NSObject <NSCopying, NSCoding>
@property(copy, nonatomic) NSSet *alertSuppressionAppIDs_deprecated;
@property(assign, nonatomic) unsigned realertCount_deprecated;
@property(retain, nonatomic) BBObserver *observer;
@property(retain, nonatomic) BBAssertion *lifeAssertion;
@property(copy, nonatomic) BBAction *expireAction;
@property(retain, nonatomic) NSDate *expirationDate;
@property(retain, nonatomic) NSMutableDictionary *actions;
@property(copy, nonatomic) NSString *unlockActionLabelOverride;
@property(retain, nonatomic) BBAttachments *attachments;
@property(retain, nonatomic) BBContent *content;
@property(retain, nonatomic) NSDate *lastInterruptDate;
@property(retain, nonatomic) NSDictionary *context;
@property(assign, nonatomic) BOOL expiresOnPublisherDeath;
@property(copy, nonatomic) NSArray *buttons;
@property(copy, nonatomic) BBAction *replyAction;
@property(copy, nonatomic) BBAction *acknowledgeAction;
@property(copy, nonatomic) BBAction *defaultAction;
@property(readonly, assign, nonatomic) int primaryAttachmentType;
@property(retain, nonatomic) BBSound *sound;
@property(assign, nonatomic) BOOL clearable;
@property(assign, nonatomic) int accessoryStyle;
@property(retain, nonatomic) NSTimeZone *timeZone;
@property(assign, nonatomic) BOOL dateIsAllDay;
@property(assign, nonatomic) int dateFormatStyle;
@property(retain, nonatomic) NSDate *recencyDate;
@property(retain, nonatomic) NSDate *endDate;
@property(retain, nonatomic) NSDate *date;
@property(retain, nonatomic) BBContent *modalAlertContent;
@property(copy, nonatomic) NSString *message;
@property(copy, nonatomic) NSString *subtitle;
@property(copy, nonatomic) NSString *title;
@property(assign, nonatomic) int sectionSubtype;
@property(assign, nonatomic) int addressBookRecordID;
@property(copy, nonatomic) NSString *publisherBulletinID;
@property(copy, nonatomic) NSString *recordID;
@property(copy, nonatomic) NSString *sectionID;
@property(copy, nonatomic) NSString *section;
@property(copy, nonatomic) NSString *bulletinID;
+ (id)bulletinWithBulletin:(id)bulletin;
- (void)_fillOutCopy:(id)copy withZone:(NSZone*)zone;
- (void)deliverResponse:(id)response;
- (id)responseSendBlock;
- (id)responseForExpireAction;
- (id)responseForButtonActionAtIndex:(unsigned)index;
- (id)responseForAcknowledgeAction;
- (id)responseForReplyAction;
- (id)responseForDefaultAction;
- (id)_responseForActionKey:(id)actionKey;
- (id)_actionKeyForButtonIndex:(unsigned)buttonIndex;
- (id)attachmentsCreatingIfNecessary:(BOOL)necessary;
- (NSUInteger)numberOfAdditionalAttachmentsOfType:(int)type;
- (NSUInteger)numberOfAdditionalAttachments;
@end

@interface SBBulletinBannerItem : NSObject {
	BBBulletin *_seedBulletin;
	NSArray *_additionalBulletins;
}
+ (id)itemWithBulletin:(BBBulletin *)bulletin;
+ (id)itemWithSeedBulletin:(BBBulletin *)seedBulletin additionalBulletins:(NSArray *)bulletins;
- (id)_initWithSeedBulletin:(BBBulletin *)seedBulletin additionalBulletins:(NSArray *)bulletins;
- (UIImage *)attachmentImage;
- (UIImage *)iconImage;
- (NSString *)_appName;
- (NSString *)title;
- (NSString *)message;
- (NSString *)attachmentText;
- (BOOL)playSound;
- (void)killSound;
- (void)sendResponse;
- (id)launchBlock;
- (BBBulletin *)seedBulletin;
@end

@interface SBBannerView : UIView {
	SBBulletinBannerItem *_item;
	UIView *_iconView;
	UILabel *_titleLabel;
	UILabel *_messageLabel;
	CGFloat _imageWidth;
	UIImageView *_bannerView;
	UIView *_underlayView;
}
- (id)initWithItem:(SBBulletinBannerItem *)item;
- (SBBulletinBannerItem *)item;
- (void)_createSubviewsWithBannerImage:(UIImage *)bannerImage;
- (UIImage *)_bannerMaskStretchedToWidth:(CGFloat)width;
- (UIImage *)_bannerImageWithAttachmentImage:(UIImage *)attachmentImage;
@end

@interface UILabel (Marquee)
- (void)setMarqueeEnabled:(BOOL)marqueeEnabled;
- (void)setMarqueeRunning:(BOOL)marqueeRunning;
- (void)_startMarquee;
@end

@interface SBBulletinBannerController : NSObject
+ (SBBulletinBannerController *)sharedInstance;
- (CGRect)_currentBannerFrameForOrientation:(UIInterfaceOrientation)orientation;
@end

@interface SBApplication (iOS5)
- (UIStatusBarStyle)statusBarStyle;
@end

@interface UIImage (UIApplicationIconPrivate)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

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
				layer.contents = (id)[UIImage kitImageNamed:DBCurrentStatusBarStyle() == UIStatusBarStyleDefault ? @"Silver_Base.png" : @"Black_Base.png"].CGImage;
				layer.contentsCenter = (CGRect){ { 0.5f, 0.0f }, { 0.0f, 1.0f } };
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

static BOOL DBShouldHideBiteSMSButton()
{
        NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.rpetrich.dietbulletin.plist"];
        NSNumber* bite = [settings objectForKey:@"DBHideBiteSMSButton"];
        return bite.boolValue;
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

%new -(void) scrollStatusBar
{
	UILabel **_titleLabel = CHIvarRef(self, _titleLabel, UILabel *);
	UILabel **_messageLabel = CHIvarRef(self, _messageLabel, UILabel *);
	__block CGRect tr = [*_titleLabel frame];
	__block CGRect mr = [*_messageLabel frame];

	float duration = ((tr.size.width + mr.size.width) / 25);
	if ((duration - 10)  > 6.5)
	{
		SBBulletinBannerController *bc = [%c(SBBulletinBannerController) sharedInstance];
		[NSObject cancelPreviousPerformRequestsWithTarget:bc selector:@selector(_dismissIntervalElapsed) object:nil];
		[bc performSelector:@selector(_dismissIntervalElapsed) withObject:nil afterDelay:duration - 10];
	}

	[UIView animateWithDuration:duration
	delay: 0
	options: UIViewAnimationOptionCurveLinear 
	animations: ^{
		tr.origin.x -= (tr.size.width + mr.size.width);
		mr.origin.x -= (tr.size.width + mr.size.width);
		[*_titleLabel setFrame:tr];
		[*_messageLabel setFrame:mr];
	}
	completion: ^(BOOL finished) {}];
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
				DBApplyMarqueeAndExtendedDelay(*_messageLabel);
				break;
			}
			case DBBulletinStyleLargeBanner:
				DBApplyMarqueeAndExtendedDelay(*_messageLabel);
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

				CGRect mr = [*_messageLabel frame];
				CGSize msize = [*_messageLabel sizeThatFits:mr.size];
				if (msize.width > mr.size.width)
				{
					CGRect tr = [*_titleLabel frame];
					CGRect mr = [*_messageLabel frame];
	
					UIView* scroll = [[[UIView alloc] initWithFrame:CGRectMake(tr.origin.x, 0, tr.size.width + mr.size.width, bounds.size.height)] autorelease];
					scroll.clipsToBounds = YES;
					[self addSubview:scroll];
	
					[scroll addSubview:*_titleLabel];
					[scroll addSubview:*_messageLabel];
	
					mr.origin.x -= tr.origin.x;
					mr.size.width = msize.width;
					mr.size.height = 19.0f;
					[*_messageLabel setFrame:mr];

					tr.origin.x = 0;
					[*_titleLabel setFrame:tr];

					[self performSelector:@selector(scrollStatusBar) withObject:nil afterDelay:1];
				}
				
				break;
			}
		}

		// handle biteSMS button
		UIView* b = [self viewWithTag:844610];
		b.hidden = DBShouldHideBiteSMSButton();
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
