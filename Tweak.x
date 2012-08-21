#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>
#import <QuartzCore/QuartzCore.h>

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

static BOOL DBShouldShowTitleForDisplayIdentifier(NSString *displayIdentifier)
{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.rpetrich.dietbulletin.plist"];
	NSString *key = [NSString stringWithFormat:@"DBShowTitle-%@", displayIdentifier];
	id value = [settings objectForKey:key];
	return !value || [value boolValue];
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
		if (DBShouldShowTitleForDisplayIdentifier(self.item.seedBulletin.sectionID)) {
			[*_titleLabel setHidden:NO];
			CGSize firstLabelSize = [*_titleLabel sizeThatFits:bounds.size];
			[*_titleLabel setFrame:(CGRect){ { 24.0f, 0.0f }, { firstLabelSize.width, 21.0f } }];
			[*_messageLabel setFrame:(CGRect){ { firstLabelSize.width + 28.0f, 1.5f }, { bounds.size.width - firstLabelSize.width - 30.0f, 21.0f } }];
		} else {
			[*_titleLabel setHidden:YES];
			[*_messageLabel setFrame:(CGRect){ { 24.0f, 1.5f }, { bounds.size.width - 26.0f, 21.0f } }];
		}
		if ([UILabel instancesRespondToSelector:@selector(setMarqueeEnabled:)] && [UILabel instancesRespondToSelector:@selector(setMarqueeRunning:)]) {
			[*_messageLabel setMarqueeEnabled:YES];
			[*_messageLabel setMarqueeRunning:YES];
		}
		[*_underlayView setHidden:YES];
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
	if (suppressMessageOverride) {
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

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init();
	textExtractors = [[NSMutableDictionary alloc] init];
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
