// C++ mapのサンプル
#include <iostream>
#include <map>
using namespace std;

typedef map<string, string> StringMap;

int main( int argc, const char** argv) {
    StringMap strmap, strmap2;
    strmap["hoge"] = "hogehoge";
    strmap["foo"] = "foofoo";
    strmap["bar"] = "barbar";

    int size = strmap.size();
    cout << "map size: " << size << endl;

    strmap2["foo"]="sfsfsfsfsf";

    for ( StringMap::iterator it = strmap.begin();
                              it != strmap.end(); it++ ) {
        const string& key = it->first;
        const string& val = it->second;
        StringMap::iterator it2 = strmap2.find(key);
        // キーの存在チェック
        if ( it2 != strmap2.end() ) {
            cout << "found! : " << key << endl;
            cout << "  " << it2->first << "  " << it2->second << endl;
        }
    }
}
