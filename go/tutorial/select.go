package main

import "fmt"
import "time"

func fibonacci(c, quit chan int) {
    x, y := 0, 1
    for {
        fmt.Printf("for %d, %d\n", x, y);
        select {
        case c <- x: // ここで、<- cされるまでブロックされる
            x, y = y, x+y
        case <-quit:
            fmt.Println("quit")
            return
        }
    }
}

func main() {
    c := make(chan int)
    quit := make(chan int)
    go func() {
        for i := 0; i < 10; i++ {
            time.Sleep( 100 * time.Millisecond )
            fmt.Printf("%d, %d\n", i, <-c) // ここで読み出すと、case c <- x が評価され、fibonacci内のloopが回る
        }
        quit <- 0
    }()
    fibonacci(c, quit)

    tick := time.Tick(100 * time.Millisecond)
    boom := time.After(500 * time.Millisecond)
    for {
        select {
        case <-tick:
            fmt.Println("tick.")
        case <-boom:
            fmt.Println("BOOM!")
            return
        default:
            fmt.Println("    .")
            time.Sleep(50 * time.Millisecond)
        }
    }
}
