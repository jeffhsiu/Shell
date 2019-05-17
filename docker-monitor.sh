#!/bin/bash

ip_addr=`ip a | grep eth0 | grep inet | grep -v inet6 | sed 's/^[ \t]*//g' | cut -d ' ' -f 2 | cut -d '/' -f 1`

wechatSend(){
	key="SCU50529T56c1fc580948bf3a0aeed1abfabb93b55ccc07bc5c204"
	title="$1"
	content="$2"
	url="https://sc.ftqq.com/${key}.send"
	# curl "https://pushbear.ftqq.com/sub?sendkey=${key}&text=${title}&desp=${content}" >/dev/null 2>&1
	curl -G --data-urlencode "text=${title}" --data-urlencode "desp=${content}" "${url}"
}

docker stats --no-stream | while read -r line
do
	((count++))
	if [[ "$count" -ge "2" ]]
	then
		container_id=$(echo $line | cut -d " " -f 1)
		name=$(echo $line | cut -d " " -f 2)
		net=$(echo $line | cut -d " " -f 8)
		net_unit=${net:0-2}
		net_val=${net:0:${#net}-2}

		echo "ContainerID: $container_id  Name: $name  NetI/O: $net"

		if [[ "${net_unit}" == "GB" && $(echo "$net_val 20" | awk '{print ($1> $2)}') -eq "1" ]]
		then
			echo "流量超出通知"
			wechatSend "流量超出通知 ${ip_addr}" "VPS IP: ${ip_addr}, Docker Name: ${name}, NetIO: ${net}"
		fi
	fi
done
