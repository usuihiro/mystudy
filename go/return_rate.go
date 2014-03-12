/*

 簡易リターンレート集計スクリプト

 golang練習用に作成

 expected: /^(YYYYMMDD)\t(id)\t(target_flg)\n$/
  ex)
    新規RRであれば、新規アクセスフラグをtarget_flgに渡す

 参考: http://blog.golang.org/go-maps-in-action

*/

package main

import (
        "fmt"
        "os"
        "bufio"
        "strings"
        "strconv"
        "sort"
)

func main() {
    scanner := bufio.NewScanner(os.Stdin)

    datem := make(map[int]int)
    statm := make(map[string]map[int]int)

    for scanner.Scan() {
        cols := strings.Split(scanner.Text(), "\t" )
        date_i, _ := strconv.Atoi(cols[0])
        uid := cols[1]
        flg := cols[2]
        if flg == "" {
            flg = "1"
        }
        flg_i, _ := strconv.Atoi( flg )
        if statm[uid] == nil {
            statm[uid] = make(map[int]int)
        }

        datem[date_i] = 1
        statm[uid][date_i] = flg_i
    }

    return_stat_m := make(map[int]map[int]int)
    var base_date_keys []int
    for key, _ := range datem {
        base_date_keys = append(base_date_keys, key )
    }

    sort.Ints(base_date_keys)
    for _, base_date := range base_date_keys {
        target_users_m := make(map[string]int)
        for id, _ := range statm {
            if val, ok := statm[id][base_date]; !ok || val == 0 { continue }
            target_users_m[id]++
        }

        for id, _ := range statm {
            if val, ok := statm[id][base_date]; !ok || val == 0 { continue }
            if _, ok := return_stat_m[base_date]; !ok {
                return_stat_m[base_date] = make(map[int]int)
            }

            return_stat_m[base_date][base_date]++
        }

        for _, offset_date := range base_date_keys {
            if offset_date <= base_date { continue }
            for id, _ := range statm {
                if _, ok := target_users_m[id]; !ok { continue }
                if _, ok := statm[id][offset_date]; !ok { continue }

                return_stat_m[base_date][offset_date]++
            }

            for id, _ := range statm {
                delete(statm[id], base_date)
            }
        }
    }

    headers := []string{"-"}
    for _, dt := range base_date_keys {
        headers = append(headers, fmt.Sprintf("%d-uu\t%d-rate", dt, dt))
    }
    fmt.Println(strings.Join(headers, "\t" ) )

    last_date := base_date_keys[ len(base_date_keys) - 1 ]

    for _, dt := range base_date_keys {
        fmt.Printf("%d\t", dt)
        for _, offset_date := range base_date_keys {
            if offset_date < dt {
                fmt.Print("-\t-")
            } else {
                var uu int
                var rate float32
                if val, ok := return_stat_m[dt][offset_date]; ok {
                    uu = val
                } else { uu = 0 }

                if val, ok := return_stat_m[dt][dt]; ok {
                    rate = float32(return_stat_m[dt][offset_date]) / float32(val) * 100.0
                } else { rate = 0 }

                fmt.Printf("%d\t%.2f%%", uu, rate )
            }
            if offset_date == last_date {
                fmt.Print("\n")
            } else {
                fmt.Print("\t")
            }
        }
    }

    if err := scanner.Err(); err != nil {
        fmt.Fprintln(os.Stderr, "reading standard input:", err)
    }
}

