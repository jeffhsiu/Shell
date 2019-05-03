#!/bin/bash

wechatSend(){
	key="11994-869a36ce1e0cf7724d2e3f7dd01b6e24"
	title="$1"
	content="$2"
	curl "https://pushbear.ftqq.com/sub?sendkey=${key}&text=${title}&desp=${content}" >/dev/null 2>&1
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
		net_val=${net:0:${#str}-2}

		echo "ContainerID: $container_id  Name: $name  NetI/O: $net"

		if [[ "${net_unit}" == "MB" && $(echo "$net_val 20" | awk '{print ($1> $2)}') -eq "1" ]]
		then
			echo "超过流量了"
		fi
	fi
done
