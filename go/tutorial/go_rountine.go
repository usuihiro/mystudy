package main;
import (
  "fmt"
  "time"
)

func say(s string) {
  for i := 0; i < 5; i++ {
    time.Sleep(100 * time.Millisecond)
    fmt.Println(s)
  }
}

func sum(a []int, c chan int) {
    sum := 0
    for _, v := range a {
        sum += v
    }
    time.Sleep(1000 * time.Millisecond)
    c <- sum // send sum to c
}

func receive(c chan int){
  a := <-c
  fmt.Println(a)
  time.Sleep(1000 * time.Millisecond)
}

func main() {
    /* a := []int{7, 2, 8, -9, 4, 0} */

    c := make(chan int)
    for i := 0; i < 30; i++ {
        go receive(c)
        c <- i
        fmt.Printf("%d sent\n", i)
    }

    /* go sum(a[:len(a)/2], c) */
    /* fmt.Println("sum1 called") */
    /* go sum(a[len(a)/2:], c) */
    /* fmt.Println("sum2 called") */
    /* x, y := <-c, <-c // receive from c */
    /* fmt.Println("receive") */

    /* fmt.Println(x, y, x+y) */
}

/* func main() { */
  /* go say("world") */
  /* say("hello") */
/* } */

