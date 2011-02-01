#import <Foundation/Foundation.h>

typedef void (^counterBlock_t)();

counterBlock_t createCounter(int init_val) {
    __block int counter = init_val;

    counterBlock_t block = [^{
        printf("counter %d\n", ++counter);
    } copy]; // copyしないとstackに確保されるためスコープを越えられない

    return block;
}

int main(void) {
    counterBlock_t block = createCounter(10);
    counterBlock_t block2= createCounter(100);

    block();
    block2();
    block();
    block2();

    [block2 release]; // copyしたらちゃんとreleaseする
    [block release];
    Block_release(block);

    return 0;
}
