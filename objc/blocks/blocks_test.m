#import <Foundation/Foundation.h>
#define N(n) [NSNumber numberWithInt:n]

int main() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSArray *array = [NSArray arrayWithObjects:
        N(0),N(1),N(2),N(3),nil];
    __block int total = 0;

    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        total += [obj intValue];
    }];
    NSLog(@"total = %d.", total);
    [pool release];
    return 0;
}
