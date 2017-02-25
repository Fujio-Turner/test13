//
//  AppDelegate.m
//  test13
//
//  Created by Fujio Turner on 9/11/16.
//  Copyright © 2016 Fujio Turner. All rights reserved.
//

#import "AppDelegate.h"

#define sgUrl @"http://localhost:4984/sync_gateway"

@interface AppDelegate ()
// shared manager
@property (strong, nonatomic) CBLManager *manager;
// the database
@property (strong, nonatomic) CBLDatabase *database;
// the replications
@property (strong, nonatomic) CBLReplication *pull;
@property (strong, nonatomic) CBLReplication *push;
@property (nonatomic) NSError *lastSyncError;

@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // create a shared instance of CBLManager
    if (![self createTheManager]) return NO;
    
    // Create a database and demonstrate CRUD operations
    BOOL result = [self sayHello];
    NSLog (@"This Hello Couchbase Lite run was a %@!", (result ? @"total success" : @"dismal failure"));
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (BOOL) sayHello {
    
    // create a database
    if (![self createTheDatabase]) return NO;
    
    //NSArray *filterC = @[@"bob",@"cake"]; //filter for push
    //[self startPull: filterC ];
    
    // create a new document & save it in the database
    //[self createTheDocument];
    
    // retrieve a document from the database
    //[self retrieveTheDocument];
    
    // update a document
    //[self updateTheDocument];
    
    // delete a document
    //[self deleteTheDocument];
    
    //[self startPush];
    
    //[self viewTitle];
    
    //[self queryTitle];
    
    return YES;
}



#pragma mark Manager and Database Methods

// creates the manager object
- (BOOL) createTheManager {
    // create a shared instance of CBLManager
    _manager = [CBLManager sharedInstance];
    if (!_manager) {
        NSLog (@"Cannot create shared instance of CBLManager");
        return NO;
    }else{
        [CBLManager enableLogging: @"Sync"];
        /*
        Logging Options: https://developer.couchbase.com/documentation/mobile/current/guides/couchbase-lite/native-api/manager/index.html
        */
        NSLog (@"Manager created");
        return YES;
    }
}


// creates the database
- (BOOL) createTheDatabase {
    
    NSError *error;
    // create a name for the database and make sure the name is legal
    NSString *dbname = @"sample-db";
    if (![CBLManager isValidDatabaseName: dbname]) {
        NSLog (@"Bad database name");
        return NO;
    }
    // create a new database
    _database = [_manager databaseNamed: dbname error: &error];
    if (!_database) {
        NSLog (@"Cannot create database. Error message: %@", error.localizedDescription);
        return NO;
    }
    
    return YES;
}


- (BOOL) createTheDocument {
    
    NSError *error;
    
    NSArray *channels = @[@"cake", @"bob", @"water"];
    // create an object that contains data for the new document
    NSDictionary *myDictionary =
    @{@"message" : @"Hello Couchbase Lite!",
      @"name" : @"Mountain View",
      @"age" : @15,
      @"channels": channels,
      @"timestamp" : [[NSDate date] description]};
    
    // display the data for the new Map
    NSLog(@"This is the data for the document: %@", myDictionary);
    
    
     // get the document from the DB by name
    CBLDocument *doc = [self.database documentWithID: @"myFirstDoc"];
    // write the document to the database
    if (![doc putProperties: myDictionary error: &error]) {
        NSLog (@"Cannot write document to database. Error message: %@", error.localizedDescription);
        return NO;
    }
   
    return YES;
}

// retrieves the document
- (BOOL) retrieveTheDocument {
    
    // retrieve the document from the database
    CBLDocument *retrievedDoc = [self.database documentWithID: @"myFirstDoc"];
    
    // display the retrieved document
    NSLog(@"The retrieved document contains: %@", retrievedDoc.properties);
    
    return YES;
}


- (BOOL) updateTheDocument{

    NSError *error;
    CBLDocument *doc = [self.database documentWithID: @"myFirstDoc"];
     
     //NSError* error;
     if (![doc update: ^BOOL(CBLUnsavedRevision *newRev)  {
     newRev[@"title"] = @"DBA";
     newRev[@"notes"] = @"its open now.";
     newRev[@"revTimeStamp"] = [[NSDate date] description];
         
     return YES;
     } error: &error]) {
         NSLog (@"Cannot write document to database. Error message: %@", error.localizedDescription);
     }
    
    return YES;
}

- (BOOL) deleteTheDocument {
    
    CBLDocument* doc = [self.database documentWithID: @"myFirstDoc"];
    // display the retrieved document
    
    NSError* error;
    if (![doc deleteDocument: &error]) {
        NSLog (@"Cannot Delete document to database. Error message: %@", error.localizedDescription);
    }else{
        NSLog(@"The Document Deleted: %@:",doc);
    }
    return YES;
}


- (void)startPush{
    
    if (_push.running){
        [_push stop];
    }
    NSURL *syncUrl = [NSURL URLWithString:sgUrl];
    _push = [self.database createPushReplication:syncUrl];
   _push.continuous = YES;
    
    [_push start];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replicationChanged:)
                                                 name: kCBLReplicationChangeNotification
                                               object: _push];
}

- (void)startPull: (NSArray*)filterChannels {
    
    if (_pull.running){
        [_pull stop];
    }
    
    NSURL *syncUrl = [NSURL URLWithString:sgUrl];
    _pull = [self.database createPullReplication:syncUrl];
    _pull.continuous = YES;
    //_pull.channels  = @[@"bob"];
    _pull.channels = filterChannels;

    [_pull start];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replicationChanged:)
                                                 name: kCBLReplicationChangeNotification
                                               object: _pull];
    
}


- (void) replicationChanged: (NSNotification*)n {
    // The replication reporting the notification is n.object , but we
    // want to look at the aggregate of both the push and pull.
    
    // First check whether replication is currently active:
    BOOL active = (_pull.status == kCBLReplicationActive) || (_push.status == kCBLReplicationActive);
    
    if (active) {
        double progress = 0.0;
        double total = _push.changesCount + _pull.changesCount;
        if (total > 0.0) {
            progress = (_push.completedChangesCount + _pull.completedChangesCount) / total;
        }
         NSLog (@"Replication Process: %f", progress);
        //self.progressBar.progress = progress;
    }
    
    if (_pull.status == kCBLReplicationActive || _push.status == kCBLReplicationActive) {
        NSLog(@"Sync in progress");
    } else {
        NSError *error = _pull.lastError ? _pull.lastError : _push.lastError;
        if (error.code == 401) {
            NSLog(@"Authentication error");
        }
        if (error.code == 503) {
            NSLog(@"DB is Currentyl under maintenance");
        }
    }
}

- (void) viewTitle{
    
    CBLView* view = [_database viewNamed: @"title"];
    [view setMapBlock: MAPBLOCK({
        if(doc[@"title"]){
            emit(doc[@"title"],nil);
        }
    }) version: @"1"];
    
    [view createQuery];
}

- (void) queryTitle{

    NSError* error;
    CBLQuery* query = [[_database viewNamed: @"title"] createQuery];
    query.descending = YES;
    query.limit = 20;

    CBLQueryEnumerator* result = [query run: &error];
    for (CBLQueryRow* row in result) {
        NSLog(@"Title is: %@", row.key);
    }
}

@end