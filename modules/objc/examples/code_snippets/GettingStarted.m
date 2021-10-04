//
//  ViewController.m
//  threeBeta01prod
//
//  Created by Ian Bridge on 04/10/2021.
//

#import "ViewController.h"
#import "CouchbaseLite/CouchbaseLite.h"

@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Get the database (and create it if it doesn’t exist).

    bool *testReplication;
    testReplication = false;

    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // Create a new document (i.e. a record) in the database.
    CBLMutableDocument *mutableDoc = [[CBLMutableDocument alloc] init];
    [mutableDoc setFloat:2.0 forKey:@"version"];
    [mutableDoc setString:@"SDK" forKey:@"type"];

    // Save it to the database.
    [database saveDocument:mutableDoc error:&error];

    // Update a document.
    CBLMutableDocument *mutableDoc2 = [[database documentWithID:mutableDoc.id] toMutable];
    [mutableDoc2 setString:@"Objective-C" forKey:@"language"];
    [database saveDocument:mutableDoc2 error:&error];

    CBLDocument *document = [database documentWithID:mutableDoc2.id];
    // Log the document ID (generated by the database)
    // and properties
    NSLog(@"Document ID :: %@", document.id);
    NSLog(@"Learning %@", [document stringForKey:@"language"]);

    // Create a query to fetch documents of type SDK.
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"SDK"]];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                          from:[CBLQueryDataSource database:database]
                                         where:type];

    // Run the query
    CBLQueryResultSet *result = [query execute:&error];
    NSLog(@"Number of rows :: %lu", (unsigned long)[[result allResults] count]);

    if (testReplication) {

        // Create replicators to push and pull changes to and from the cloud.
        NSURL *url = [[NSURL alloc] initWithString:@"ws://localhost:4984/getting-started-db"];
        CBLURLEndpoint *targetEndpoint = [[CBLURLEndpoint alloc] initWithURL:url];
        CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:targetEndpoint];
        replConfig.replicatorType = kCBLReplicatorTypePushAndPull;

        // Add authentication.
        replConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];

        // Create replicator (make sure to add an instance or static variable named _replicator)
        CBLReplicator *_replicator = [CBLReplicator alloc];
        _replicator = [[CBLReplicator alloc] initWithConfig:replConfig];

        // Listen to replicator change events.
        [_replicator addChangeListener:^(CBLReplicatorChange *change) {
            if (change.status.error) {
                NSLog(@"Error code: %ld", change.status.error.code);
            }
        }];

        // Start replication
        [_replicator start];

    }
}


@end
