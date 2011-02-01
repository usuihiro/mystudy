#import <Foundation/Foundation.h>

typedef void (^block_t)();

void capture_const() {
    NSString *label = [NSString stringWithFormat:@"hello"];
    NSLog(@"0: label retainCount = %lu", [label retainCount]);

    block_t block_on_stack = ^{NSLog(@"label[%@]", label);};
    NSLog(@"1: label retainCount=%lu", [label retainCount]);

    // copyするとキャプチャしたオブジェクトもretainされる
    block_t block_on_heap = [block_on_stack copy];
    NSLog(@"2: label retainCount=%lu", [label retainCount]);

    // blockのreleaseで参照カウントがひつと減る
    [block_on_heap release];
    NSLog(@"3: label retainCount=%lu", [label retainCount]);
}

void capture_block() {
    __block NSString *label = [NSString stringWithFormat:@"hello"];
    NSLog(@"0: label retainCount = %lu", [label retainCount]);

    block_t block_on_stack = ^{NSLog(@"label[%@]", label);};
    NSLog(@"1: label retainCount=%lu", [label retainCount]);

    // copyしてもlabelの参照カウントは増えない。なぜならlabelの参照先をblock内で変更できるから
    block_t block_on_heap = [block_on_stack copy];
    NSLog(@"2: label retainCount=%lu", [label retainCount]);

    // releaseしてもlabelの参照カウントは減らない。
    [block_on_heap release];
    NSLog(@"3: label retainCount=%lu", [label retainCount]);
}


@interface TestObject: NSObject
{
    NSString *string_;
    block_t block_;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic, retain) block_t block;

@end
@implementation TestObject

@synthesize string=string_;
@synthesize block=block_;

-(id)init
{
    self = [super init];
    self.string = [NSString stringWithFormat:@"Hello"];


    block_t block;

#if 0
    /* 直接メンバを参照するとselfがretainされるため循環参照を引き起こす
    block = Block_copy(^{
            NSLog(@"BLOCK! %@", string_);
            NSLog(@"BLOCK! %@", self.string);
    });
#else

    /* 循環参照回避策。いったんローカル変数に代入する */
    NSString *string = self.string;
    block = Block_copy(^{
        NSLog(@"BLOCK! %@", string );
    });
#endif

    self.block = [block autorelease];
    return self;
}

-(void) dealloc
{
    self.block = nil;
    self.string = nil;
    [super dealloc];
}

@end

int main() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

    capture_const();
    capture_block();

    [pool release];

    return 0;
};
