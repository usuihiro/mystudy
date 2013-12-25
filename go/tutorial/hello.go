package main

import (
    "fmt"
)

var x, y, z int = 1,2,3
var c, python, java = true, false, "no!"

func swap( x, y string) (string, string) {
    return y, x
}

func add( x , y int) int {
    return x + y
}

func split(sum int) (x, y int) {
    x = sum * 4 /9
    y = sum - x
    return
}

func main() {
    fmt.Println(add(3,5))
    fmt.Println(swap("Hello", "world"))
    fmt.Println(split(17))
    fmt.Println(x, y, z, c, python, java)
}

