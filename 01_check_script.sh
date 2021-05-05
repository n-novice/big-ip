#!/bin/bash

echo "Start" 
/usr/bin/expect <(cat <<'EOF'

#初期パラメータ設定
set send_slow {1 .01}
set timeout 5
set NOW [ exec date "+%Y%m%d%H%M%S" ]

#定義
#set logfile "./log/LTMStatus.[clock format [clock seconds] -format %Y%m%d%H%M%S]"
set logfile "/home/pi/script2/log/LTMStatus.$NOW.txt"

# IPリストをファイルから取得する
set host_file1 "list.txt"
if {![file readable $host_file1]} {
    error "cannot read $host_file1"
}
set fid1 [open $host_file1 r]

#ログ取得開始
log_file $logfile

while {[gets $fid1 ip] != -1} {

    # コマンドをファイルから取得する
    set host_file2 "/home/pi/script2/command/Command_LTM01_Status_Check.txt"
    if {![file readable $host_file2]} {
        error "cannot read $host_file2"
    }
    set fid2 [open $host_file2 r]

    spawn ssh $ip  -l Operator
    expect "Password:"
    send -s -- "P@ssw0rd\r"

    expect "Operator@"
    send -s -- "\r"

    expect "Operator@"
    send -s -- "##################################################\r"

    expect "Operator@"
    send -s -- "show sys clock\r"

    while {[gets $fid2 command] != -1} {
        expect "Operator@"
        send -s -- $command
        send -s -- "\r"

	expect {
            -ex "less" { send -s -- " "; exp_continue }
            "(END)" { send -s -- "q\r" }
        }

        expect "Operator@"
        send -s -- "\r"
        expect "Operator@"
        send -s -- "###############################################################################\r"
        expect "Operator@"
        send -s -- "\r"
        expect "Operator@"
        send -s -- "\r"

    }

    expect "Operator@"
    send -s -- "quit\r"

    expect eof
    sleep 1

    #コマンド用ファイルクローズ
    close $fid2
}

#ホスト情報ファイルクローズ・ログ取得終了
close $fid1
log_file
EOF
)
echo "END"
LOGFILE=`ls -1t ./log/*.txt | head -1`
echo $LOGFILE
cat $LOGFILE | sed 's/---(less .*)---//' > $LOGFILE.2


