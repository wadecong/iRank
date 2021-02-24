#! /bin/sh

# Copyright (c) 2012 yuzebin.com
# Copyright (c) 2012 yuzebin.com <yuzebin(at)gmail(dot)com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

CURL=curl
GZIP=gzip
GREP=grep
AWK=awk
SED=sed
DIFF=/usr/bin/diff

file_path=./rank/

usage()
{
    echo ""
    echo "irank: "
    echo "  get and view the app store top rank"
    echo "      version 0.1"
    echo "  usage: $0 <command> [options ...]"
    echo "    <command>       Command to be executed\n"
    echo ""
    echo "  Valid commands are:"
    echo "    get   get the top rank from appstore"
    echo "          usage : $0 get cn|jp free|paid|grossing|weather"
    echo ""
    echo "    view  view the specific app's rank"
    echo "          usage : $0 view cn|jp free|paid|grossing|weather [app_name [recent_change_times]]"
    echo "    diff  record the changes of rank"
    echo "          usage : $0 diff cn|jp free|paid|grossing|weather"
    echo ""
    exit 1
}

set_store()
{
    country_code=$1
    case $1 in
        cn)
            # chinese store
            store_front=143465-19,4
            store_front_pad=143465-19,9
            ;;
        jp)
            # japanese store
            store_front=143462-9,4
            store_front_pad=143462-9,9
            ;;
        *)
            exit 1
            ;;
    esac

    file_prefix=$country_code
    file_prefix_pad="$country_code"_pad

    # define rank url for iPhone
    free_url="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?selected-tab-index=1&top-ten-m=42&genreId=36"
    paid_url="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?selected-tab-index=0&top-ten-m=42&genreId=36"
    grossing_url="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?selected-tab-index=2&top-ten-m=42&genreId=36"
    weather_url="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAutoSourcedGenrePage?id=6001&selected-tab-index=1&top-ten-m=42"

    # define rank url for iPad
    paid_url_pad="http://itunes.apple.com/WebObjects/MZStore.woa/wa/topChartFragmentData?cc=$country_code&genreId=36&pageSize=120&popId=47&pageNumbers=0%2C1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9"
    grossing_url_pad="http://itunes.apple.com/WebObjects/MZStore.woa/wa/topChartFragmentData?cc=$country_code&genreId=36&pageSize=120&popId=46&pageNumbers=0%2C1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9"
    free_url_pad="http://itunes.apple.com/WebObjects/MZStore.woa/wa/topChartFragmentData?cc=$country_code&genreId=36&pageSize=120&popId=44&pageNumbers=0%2C1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9"

    # set the cookies for iPhone
    cookies=(
        "Host: itunes.apple.com" \
        "User-Agent: iTunes-iPod/5.1.1 (4; 8GB; dt:71)" \
        "Accept: */*" \
        "X-Apple-Partner: origin.0" \
        "X-Apple-Connection-Type: WiFi" \
        "X-Apple-Client-Application: Software" \
        "X-Apple-Client-Versions: GameCenter/2.0" \
        "X-Dsid: 400453337" \
        "X-Apple-Store-Front: $store_front" \
        "Accept-Language: zh-cn" \
        "Accept-Encoding: gzip, deflate" \
        "Connection: keep-alive"
        )
    
    # set the cookies for iPad
    cookies_pad=(
        "Host: itunes.apple.com" \
        "User-Agent: iTunes-iPad-M/5.1.1 (5; 32GB; dt:78)" \
        "Accept: */*" \
        "X-Apple-Client-Versions: iBooks/2.2; iTunesU/1.3; GameCenter/2.0" \
        "X-Apple-Partner: origin.0" \
        "X-Apple-Connection-Type: WiFi" \
        "X-Dsid: 1085955902" \
        "X-Apple-Store-Front: $store_front_pad" \
        "X-Apple-Client-Application: Software" \
        "Accept-Language: zh-cn" \
        "Accept-Encoding: gzip, deflate" \
        "Connection: keep-alive"
        )
}

get_rank()
{
    filename="$file_path""$file_prefix"_$1_`date +%Y%m%dT%H%M`.txt
    format_command=" | $GZIP -d | $GREP \<key\>title\<\/key\> | $AWK -F'<string>' '{print \$2}' | $SED -e 's:\<\/string\>::g' > $filename"

    curl_cookie_param=

    for c in "${cookies[@]}";
        do
        curl_cookie_param=`echo $curl_cookie_param -H \"$c\"`;
    done

    curl_command_line="$CURL -L $curl_cookie_param \"$2\"$format_command"
    # echo $curl_command_line
    eval "$curl_command_line"
    echo "rank is stored in file $filename"
    head -n 105 $filename > $filename.top100
}

get_rank_pad()
{
    filename="$file_path""$file_prefix_pad"_$1_`date +%Y%m%dT%H%M`.txt
    format_command=" | $GZIP -d | $SED -e 's:\,\ \":\n:g' | $GREP name | $GREP -v artist | $SED -e 's/name\"\:\"//' -e 's/\"//' > $filename"
    curl_cookie_param=

    for c in "${cookies_pad[@]}";
        do
        curl_cookie_param=`echo $curl_cookie_param -H \"$c\"`;
    done

    curl_command_line="$CURL -L $curl_cookie_param \"$2\"$format_command"
    # echo $curl_command_line
    eval "$curl_command_line"
    echo "rank is stored in file $filename"
    head -n 105 $filename > $filename.top100
}

do_get()
{
    if [ $# -eq 2 ]; then
        case $2 in
            paid|free|grossing|weather)
                set_store $1
                get_rank "$2" `eval echo "\$"$2"_url"`
                get_rank_pad "$2" `eval echo "\$"$2"_url_pad"`
                ;;
            *)
                usage
                ;;
        esac
    else
        usage;
    fi
}

do_view()
{
    country=$1
    
    if [ $# -eq 4 ]; then
        echo "==== iPhone ===="
        echo "  $3 @ $2 : ";
        grep -H -e "$3" "$file_path""$country"_$2*.txt | sed -e "s:^:    :" -e "s:</string>::" -e "s:\.txt\:: :" -e "s:$4$5\_::" -e "s:T: :" -e "s:\(\ [0-9][0-9]\)\([0-9][0-9]\ \):\1\:\2:" -e "s:\(\ [0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\ \):\1\-\2\-\3:" | tail -n $4;
        echo "";
        echo "==== iPad ===="
        echo "  $3 @ $2 : ";
        grep -H -e "$3" "$file_path""$country"_pad_$2*.txt | sed -e "s:^:    :" -e "s:</string>::" -e "s:\.txt\:: :" -e "s:$4$5\_::" -e "s:T: :" -e "s:\(\ [0-9][0-9]\)\([0-9][0-9]\ \):\1\:\2:" -e "s:\(\ [0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\ \):\1\-\2\-\3:" | tail -n $4;
        echo "";
    else
        if [ $# -eq 3 ]; then
            echo "==== iPhone ===="
            cat `ls -t "$file_path""$country"_"$2"_*.txt | head -n 1` | grep $3
            echo "";
            echo "==== iPad ===="
            cat `ls -t "$file_path""$country"_pad_"$2"_*.txt | head -n 1` | grep $3
            echo "";
        else
            if [ $# -eq 2 ]; then
                echo "==== iPhone ===="
                cat `ls -t "$file_path""$country"_"$2"_*.txt | head -n 1` | head -n 54
                echo "";
                echo "==== iPad ===="
                cat `ls -t "$file_path""$country"_pad_"$2"_*.txt | head -n 1` | head -n 50
                echo "";
            else
                usage;
            fi
        fi
    fi
}
    
get_diff()
{
    $DIFF -q `ls -t $file_path$1_$2*.txt | head -n 2` >>"$file_path"chg/$1_$2_chg.txt
    $DIFF -q `ls -t $file_path$1_$2*.top100 | head -n 2` >>"$file_path"chg/top100_$1_$2_chg.txt
}

do_diff()
{
    app_rank=(
        "paid" \
        "free" \
        "grossing" \
    )
    
    for t in "${app_rank[@]}";
        do
        get_diff cn $t;
        get_diff jp $t;
        get_diff cn_pad $t;
        get_diff jp_pad $t;
    done
}

if [ $# -eq 0 ]; then usage; fi 

case $1 in
    get)
        # do_get cn|jp free|paid|grossing|weather
        do_get $2 $3
        ;;
    view)
        # do_view cn|jp free|paid|grossing|weather [app_name [recent_change_times]]
        do_view $2 $3 $4 $5
        ;;
    diff)
        # do_diff cn|jp free|paid|grossing|weather
        do_diff $2 $3
        ;;
    *)
        echo "unknown command $1"; usage; exit 1
        ;;
esac

