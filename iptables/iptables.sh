#!/bin/bash

idc=$(hostname |cut -d "." -f2)
URL='http://cq01-oped-dev01.cq01:8080/sources/latest?service=nmg02&format=plain'

#总超时：20s ; 链接超时：5s ; 重试间隔：3s ; 重试次数：2次
curl_res=$(curl -s -m 20 --connect-timeout 5 --retry-delay 3 --retry 2 "${URL}" > /tmp/hbase)

#curl结果的行数是否符合预期
if [[ $(cat /tmp/hbase | wc -l) -ne 11 ]];then
    exit 1
fi

#curl内容是否符合预期
grep -Eq 'timestamp:' /tmp/hbase || exit 1

#将机器相关行写入文件中
grep -Ev 'timestamp|unknown' /tmp/hbase > /tmp/hbase_acc
#拿出机器列表
cut -d ':' -f 1 /tmp/hbase_acc > /tmp/hbase_list

#machine_list=$(get_hosts_by_path baidu_oped_noah_bns|grep noah-bns|sort |uniq >/tmp/bns)
#matrix_bns_list=$(get_hosts_by_path baidu_oped_docker_machine|grep noah|sort |uniq >>/tmp/bns)
#patrol_list=$(get_instance_by_service patrol.noah.all|grep noah-patrol|grep $idc>>/tmp/bns)

machine_num=$(cat /tmp/hbase_list | wc -l)

if [ "$machine_num" -gt 8  ];then
    echo "machine_num:$machine_num"
else
    exit 1
fi


/sbin/iptables -F || exit 1

for i in $(cat /tmp/hbase_list );
do
    ip=$(dig $i +short)
    /sbin/iptables -I INPUT -p tcp -m tcp -s $ip --dport 19601 -j DROP 
done
/sbin/iptables -A INPUT -p tcp -m tcp -s 127.0.0.1 --dport 19601  -j ACCEPT
/sbin/iptables -A INPUT -p tcp -m tcp --dport 19601  -j ACCEPT

rm -f /tmp/hbase_acc /tmp/hbase /tmp/hbase_list

iptables_num=$(/sbin/iptables -nL|grep 19601|wc -l)

((iptables_result=$iptables_num-$machine_num))

# iptables_result=machine_num+drop_record, so machine_num+1=iptables_num
if [ $iptables_result -eq 2 ];then
    echo "iptables_status:0"
else
    echo "iptables_status:1"    
fi
