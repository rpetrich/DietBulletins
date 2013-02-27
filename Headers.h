#import <SpringBoard/SpringBoard.h>

// Because I'm too lazy to create legitimate headers :P

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
- (void)observer:(id)observer addBulletin:(BBBulletin *)bulletin forFeed:(NSInteger)feed;
@end

@interface SBApplication (iOS5)
- (UIStatusBarStyle)statusBarStyle;
@end

@interface UIImage (UIApplicationIconPrivate)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface BBBulletinRequest : BBBulletin
@end

@interface BBAction : NSObject
+ (BBAction *)actionWithLaunchURL:(NSURL *)url callblock:(id)block;
@end
