//
//  MeoCore.h
//  MeoMeo Core Security & License Engine (iOS Static Library)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MeoAuthCompletion)(BOOL success, NSString * _Nullable error);
typedef void (^MeoStatusCompletion)(BOOL success);
typedef void (^MeoInjectCompletion)(BOOL success, NSString * _Nullable error);
typedef void (^MeoLiveStateCallback)(BOOL active);
typedef void (^MeoTokenRefreshCallback)(void);
typedef void (^MeoTerminatedCallback)(NSString *reason);

@interface MeoCore : NSObject

// License & Authentication Status
@property (nonatomic, readonly) BOOL isAuthed;
@property (nonatomic, copy, readonly, nullable) NSString *authError;
@property (nonatomic, copy, readonly) NSString *deviceId;
@property (nonatomic, copy) NSString *storedKey;
@property (nonatomic, copy, readonly) NSString *deviceExpires;
@property (nonatomic, readonly) BOOL systemActive;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSNumber *> *serverFeatures;

// Callbacks from License Engine
@property (nonatomic, copy, nullable) MeoLiveStateCallback onLiveStateChanged;
@property (nonatomic, copy, nullable) MeoTokenRefreshCallback onTokenRefreshed;
@property (nonatomic, copy, nullable) MeoTerminatedCallback onLicenseTerminated;

// Mod Settings (Config State managed inside libmeo.a)
@property (nonatomic, assign) BOOL espMaster;
@property (nonatomic, assign) BOOL espBox;
@property (nonatomic, assign) BOOL espLine;
@property (nonatomic, assign) BOOL espName;
@property (nonatomic, assign) BOOL espHealth;
@property (nonatomic, assign) BOOL espDistance;
@property (nonatomic, assign) BOOL espTracer;
@property (nonatomic, assign) BOOL espSkeleton;

@property (nonatomic, assign) BOOL aimEnabled;
@property (nonatomic, assign) BOOL aimSystemEnabled;
@property (nonatomic, assign) BOOL espFov;
@property (nonatomic, assign) BOOL noRecoil;
@property (nonatomic, assign) NSInteger aimTarget;
@property (nonatomic, assign) float fovSize;
@property (nonatomic, assign) float headshotRate;

+ (instancetype)shared;

// Anti-tamper & Security checks
+ (BOOL)isDebuggerAttached;
+ (BOOL)isHooked;

// Authentication
- (void)authenticateWithKey:(NSString *)key completion:(MeoAuthCompletion)completion;
- (void)startHeartbeat;
- (void)stopHeartbeat;
- (void)checkStatusWithCompletion:(MeoStatusCompletion)completion;

// Config Management (Automatic serialization & sync to game container)
- (void)loadConfig;
- (void)saveAndSyncConfigForBundleID:(NSString *)bundleID;
- (void)resetAllFeatures;

// Game Patch & Injection
- (void)injectToGameWithBundleID:(NSString *)bundleID completion:(MeoInjectCompletion)completion;
- (void)uninstallModFromGameWithBundleID:(NSString *)bundleID;
- (BOOL)isModInjectedForBundleID:(NSString *)bundleID;

// DNS Configuration
+ (NSString *)dnsDisplayName;
+ (NSString *)dohServerURL;
+ (NSArray<NSString *> *)dnsBootstrapServers;
+ (NSString *)dnsPayloadURL;

@end

NS_ASSUME_NONNULL_END
