#!/bin/bash

ip_addr=`curl -s ifconfig.me`
net_limit=50  # 單位是GB
mem_limit=75  # 單位是MiB
cpu_limit=25  # 單位是%

wechatSend(){
	key="SCU50529T56c1fc580948bf3a0aeed1abfabb93b55ccc07bc5c204"
	url="https://sc.ftqq.com/${key}.send"
	curl -G --data-urlencode "text=$1" --data-urlencode "desp=$2" "${url}" > /dev/null 2>&1
}

netPush(){
	url="http://v2ray.jeffhsiu.com/api/push/net"
	curl -G --data-urlencode "ip=${ip_addr}" --data-urlencode "docker_name=${1}" --data-urlencode "net=${2}" "${url}" > /dev/null 2>&1
}

docker stats --no-stream | while read -r line
do
	((count++))
	if [[ "$count" -ge "2" ]]
	then
		container_id=$(echo $line | cut -d " " -f 1)
		name=$(echo $line | cut -d " " -f 2)
		cpu=$(echo $line | cut -d " " -f 3)
		mem=$(echo $line | cut -d " " -f 4)
		net=$(echo $line | cut -d " " -f 8)

		cpu_val=${cpu:0:${#cpu}-1}

		mem_unit=${mem:0-3}
		mem_val=${mem:0:${#mem}-3}

		net_unit=${net:0-2}
		net_val=${net:0:${#net}-2}

		echo "ContainerID: $container_id  Name: $name  CPU%: $cpu  Mem: $mem  NetI/O: $net"

		# CPU 監控
		if [[ $(echo "${cpu_val} ${cpu_limit}" | awk '{print ($1> $2)}') -eq "1" ]]
		then
			echo "CPU使用率過高"
			title="CPU使用率過高_${ip_addr}"
			content="VPS IP_${ip_addr}，Docker Name_${name}，CPU %_${cpu}，Mem_${mem}，NetIO_${net}，ContainerID_${container_id}"
			wechatSend "${title}" "${content}"
		fi

		# Memory 監控
		if [[ $(echo "${mem_val} ${mem_limit}" | awk '{print ($1> $2)}') -eq "1" ]]
		then
			echo "Memory使用量過高"
			title="Memory使用量過高_${ip_addr}"
			content="VPS IP_${ip_addr}，Docker Name_${name}，CPU %_${cpu}，Mem_${mem}，NetIO_${net}，ContainerID_${container_id}"
			wechatSend "${title}" "${content}"
		fi

		# 網路流量監控，超出限制的話就stop
		if [[ "${net_unit}" == "GB" && $(echo "${net_val} ${net_limit}" | awk '{print ($1> $2)}') -eq "1" ]]
		then
			echo "Net流量超出限制"
			docker stop "${name}"
			netPush "${name}" "${net}"
		fi
	fi
done
