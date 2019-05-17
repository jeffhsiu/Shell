#!/bin/bash

ip_addr=`ip a | grep eth0 | grep inet | grep -v inet6 | sed 's/^[ \t]*//g' | cut -d ' ' -f 2 | cut -d '/' -f 1`
net_limit=50  # 單位是GB
mem_limit=50  # 單位是MiB
cpu_limit=10  # 單位是%

wechatSend(){
	key="SCU50529T56c1fc580948bf3a0aeed1abfabb93b55ccc07bc5c204"
	url="https://sc.ftqq.com/${key}.send"
	curl -G --data-urlencode "text=$1" --data-urlencode "desp=$2" "${url}" > /dev/null 2>&1
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
			content="VPS IP: ${ip_addr}，Docker Name: ${name}，ContainerID: ${container_id}，CPU %: ${cpu}，Mem: ${mem}，NetIO: ${net}"
			wechatSend "${title}" "${content}"
		fi

		# Memory 監控
		if [[ $(echo "${mem_val} ${mem_limit}" | awk '{print ($1> $2)}') -eq "1" ]]
		then
			echo "Memory使用量過高"
			title="Memory使用量過高_${ip_addr}"
			content="VPS IP: ${ip_addr}，Docker Name: ${name}，ContainerID: ${container_id}，CPU %: ${cpu}，Mem: ${mem}，NetIO: ${net}"
			wechatSend "${title}" "${content}"
		fi

		# 網路流量監控
		if [[ "${net_unit}" == "GB" && $(echo "${net_val} ${net_limit}" | awk '{print ($1> $2)}') -eq "1" ]]
		then
			echo "Net流量超出限制"
			title="Net流量超出通知_${ip_addr}"
			content="VPS IP: ${ip_addr}，Docker Name: ${name}，ContainerID: ${container_id}，CPU %: ${cpu}，Mem: ${mem}，NetIO: ${net}，已停止該服務"
			wechatSend "${title}" "${content}"
			docker stop "${name}"
		fi
	fi
done
