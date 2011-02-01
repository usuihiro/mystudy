#import <Foundation/Foundation.h>
#import <stdio.h>

int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

    NSArray *arr = [NSArray arrayWithObjects:@"hoge", @"foo", @"bar", nil];
    for ( NSString* str in arr ) {
        printf("%s\n", [str UTF8String]);
    }

    [pool release];

    return 0;
}
