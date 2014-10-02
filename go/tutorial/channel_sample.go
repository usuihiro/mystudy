// チャンネルで並列数を制限しつつ仕事を非同期で実行するサンプル
//
// 参考: http://jxck.hatenablog.com/entry/20130414/1365960707
package main

import (
	"fmt"
	"log"
	"sync"
	"time"
)

func DoTask( task string ) string {
	log.Printf("received task: %v\n", task )
	time.Sleep( 1 * time.Second )
	result := fmt.Sprintf("result: %v", task )
	log.Printf("%v done\n", task )
	return result
}

func main() {
	limit := make( chan bool, 3 ) // 並列数を制限するチャンネル
	var wg sync.WaitGroup // 総ての処理を待つためのオブジェクト

	for i := 0; i < 10; i ++ {
		wg.Add(1)
		limit <- true
		task := fmt.Sprintf("task %d", i )
		go func( t string) {
			defer func() { <- limit; wg.Done() }()
			r := DoTask( t )
			log.Printf("got result: %v", r )
		}( task )
	}

	wg.Wait()
	log.Printf("all done\n")
}
