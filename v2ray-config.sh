#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
purple="\033[35m"
dgreen="\033[36m"
colorend="\033[0m"

echo "請選擇VPS類型:"
echo "  ${green}1.${colorend} Bandwagon Host"
echo "  ${green}2.${colorend} Google Cloud"
read -p "請輸入選項: " vps
vps=${vps:-1}
read -p "請輸入ip: " ip
if [[ ${vps} == "1" ]]
then
    read -p "請輸入ssh port: " ssh_port
fi
read -p "請輸入password: " ssh_pwd
read -p "請輸入index (R開頭代表循環): " index
read -p "請輸入alterId (預設100): " alter_id

# 參數處理
index=${index:-1}
if [[ ${index:0:1} == "R" ]]
then
    index_start=${index:1:1}
    index_end=${index:3}
else
    index_start=${index}
    index_end=${index}
fi
alter_id=${alter_id:-100}
ssh_port=${ssh_port:-22}
case ${vps} in
	1) path="/Users/Jeff.Lin/Documents/V2ray-Account/Bandwagon/${ip}" ;;
	2) path="/Users/Jeff.Lin/Documents/V2ray-Account/Google/${ip}" ;;
esac

scp_config()
{
	echo
	echo "SCP v2ray config..."
	sshpass -p ${ssh_pwd} scp -P ${ssh_port} \
		/usr/local/etc/v2ray/config.json \
		root@${ip}:/etc/v2ray/config-${index}.json
	echo "SCP success!"
	echo
}

docker_run()
{
	echo "執行遠程主機 docker run..."
	container_id=`sshpass -p ${ssh_pwd} ssh -p ${ssh_port} root@${ip} \
		"docker run -d --name=v2ray-${index} -v /etc/v2ray:/etc/v2ray \
		-p ${port}:${port} --memory=80M --restart=always v2ray/official  \
		v2ray -config=/etc/v2ray/config-${index}.json"`
	echo "Docker run success! ContainID: ${container_id}"
	echo
}

create_v2ray_config()
{
	cat << EOF > /usr/local/etc/v2ray/config.json
{
    "log": {
        "access": "/var/log/v2ray/access.log",
        "error": "/var/log/v2ray/error.log",
        "loglevel": "warning"
    },
    "inbound": {
        "port": ${port},
        "protocol": "vmess",
        "settings": {
            "clients": [
                {
                    "id": "${v2ray_id}",
                    "level": 1,
                    "alterId": ${alter_id}
                }
            ]
        }
    },
    "outbound": {
        "protocol": "freedom",
        "settings": {}
    },
    "inboundDetour": [],
    "outboundDetour": [
        {
            "protocol": "blackhole",
            "settings": {},
            "tag": "blocked"
        }
    ],
    "routing": {
        "strategy": "rules",
        "settings": {
            "rules": [
                {
                    "type": "field",
                    "ip": [
                        "0.0.0.0/8",
                        "10.0.0.0/8",
                        "100.64.0.0/10",
                        "127.0.0.0/8",
                        "169.254.0.0/16",
                        "172.16.0.0/12",
                        "192.0.0.0/24",
                        "192.0.2.0/24",
                        "192.168.0.0/16",
                        "198.18.0.0/15",
                        "198.51.100.0/24",
                        "203.0.113.0/24",
                        "::1/128",
                        "fc00::/7",
                        "fe80::/10"
                    ],
                    "outboundTag": "blocked"
                }
            ]
        }
    }
}
EOF
}

create_vmess_URL_config()
{
	cat << EOF > /usr/local/etc/v2ray/vmess_qr.json
{
	"v": "2",
	"ps": "wechat:fastrabbit666",
	"add": "${ip}",
	"port": "${port}",
	"id": "${v2ray_id}",
	"aid": "${alter_id}",
	"net": "tcp",
	"type": "none",
	"host": "",
	"path": "",
	"tls": ""
}
EOF
}

echo_v2ray_vmess_URL_link()
{
	local vmess="vmess://$(cat /usr/local/etc/v2ray/vmess_qr.json | base64 -b 0)"
	echo
	echo "${red}---------- V2Ray vmess URL -------------${colorend}"
	echo
	echo " ${vmess}"
	echo
}

echo_v2ray_config_qr_link()
{
	local vmess="vmess://$(cat /usr/local/etc/v2ray/vmess_qr.json | base64 -b 0)"
        local link="http://chart.apis.google.com/chart?cht=qr&chs=360&chl=${vmess}"
        echo
        echo "${red}---------- V2Ray QrCode Link -------------${colorend}"
        echo
        echo " ${link}"
        echo
        echo " ${yellow}友情提醒: 请务必核对扫码结果${colorend}"
        echo
}

echo_v2ray_info()
{
    echo
    echo "${red}------------- V2Ray 配置信息 -------------${colorend}"
    echo
    echo "${yellow} 地址 (Address)${colorend} = ${blue}${ip}${colorend}"
    echo
    echo "${yellow} 端口 (Port)${colorend} = ${blue}${port}${colorend}"
    echo
    echo "${yellow} 用户ID (User ID / UUID)${colorend} = ${blue}${v2ray_id}${colorend}"
    echo
    echo "${yellow} 額外ID (Alter Id)${colorend} = ${blue}${alter_id}${colorend}"
    echo
    echo "${yellow} 傳輸協議 (Network)${colorend} = ${blue}tcp${colorend}"
    echo
    echo "${yellow} 偽裝類型 (header type)${colorend} = ${blue}none${colorend}"
    echo
    echo "${red}----------------- END -----------------${colorend}"
    echo
    echo
}

export_config()
{
	if [ ! -d ${path} ]; then
		mkdir -p ${path}
	fi
	local vmess="vmess://$(cat /usr/local/etc/v2ray/vmess_qr.json | base64 -b 0)"
	cat << EOF > ${path}/config-${index}.txt	
------------- V2Ray 配置信息 -------------
 地址 (Address) = ${ip}
 端口 (Port) = ${port}
 用户ID (User ID / UUID) = ${v2ray_id}
 額外ID (Alter Id) = ${alter_id}
 傳輸協議 (Network) = tcp
 偽裝類型 (header type) = none
------------------ END ------------------


---------- V2Ray vmess URL -------------
${vmess}
EOF
}

export_qrcode()
{
	if [ ! -d ${path} ]; then
		mkdir -p ${path}
	fi

	local vmess="vmess://$(cat /usr/local/etc/v2ray/vmess_qr.json | base64 -b 0)"
	link="http://api.jeffhsiu.com/qrcode/create?size=460&error=Q&text=${vmess}"
	wget -O ${path}/qrcode-${index}.png ${link}
}

for i in `seq ${index_start} ${index_end}`
do
    index=`echo ${i}|awk '{printf("%02d\n",$0)}'`
    v2ray_id=$(uuidgen | tr "[:upper:]" "[:lower:]")
    port=`expr 5550 + ${index}`
    create_v2ray_config
    create_vmess_URL_config
    scp_config
    docker_run
    export_config
    export_qrcode
    echo_v2ray_info
    rm -f /usr/local/etc/v2ray/vmess_qr.json
    rm -f /usr/local/etc/v2ray/config.json
done
