

#!/bin/bash

read -p "Google帳號: " google_account
read -p "请输入ip: " ip
read -p "请输入index: " index
read -p "请输入alterId: " alter_id

index=${index:-1}
alter_id=${alter_id:-100}
v2ray_id=$(uuidgen | tr "[:upper:]" "[:lower:]")
port=698${index}

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
purple="\033[35m"
dgreen="\033[36m"
colorend="\033[0m"

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
	echo "${yellow} 额外ID (Alter Id)${colorend} = ${blue}${alter_id}${colorend}"
	echo
	echo "${yellow} 传输协议 (Network)${colorend} = ${blue}tcp${colorend}"
	echo
	echo "${yellow} 伪装类型 (header type)${colorend} = ${blue}none${colorend}"
	echo
	echo "${red}----------------- END -----------------${colorend}"
	echo
	echo "${green}Docker启动Command${colorend}"
	echo docker run -d --name v2ray-${index} -v /etc/v2ray:/etc/v2ray -p 698${index}:698${index} --restart=always v2ray/official  v2ray -config=/etc/v2ray/config-${index}.json
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

scp_config()
{
	echo 
	scp /usr/local/etc/v2ray/config.json ${google_account}@${ip}:/etc/v2ray/config-${index}.json
	echo
}

create_vmess_URL_config()
{
	cat << EOF > /usr/local/etc/v2ray/vmess_qr.json
{
	"v": "2",
	"ps": "v2ray-${ip}:${port}",
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
	echo "${red}---------- V2Ray vmess URL / V2RayNG v0.4.1+ / V2RayN v2.1+ / 仅适合部分客户端 -------------${colorend}"
	echo
	echo " ${vmess}"
	echo
}

echo_v2ray_config_qr_link()
{
	local vmess="vmess://$(cat /usr/local/etc/v2ray/vmess_qr.json | base64 -b 0)"
        local link="http://chart.apis.google.com/chart?cht=qr&chs=400&chl=${vmess}"
        echo
        echo "${red}---------- V2Ray 二维码链接 适用于 V2RayNG v0.4.1+ / Kitsunebi -------------${colorend}"
        echo
        echo " ${link}"
        echo
        echo " ${yellow}友情提醒: 请务必核对扫码结果 (V2RayNG 除外)${colorend}"
        echo
}

export_config()
{
	if [ ! -d /Users/Jeff.Lin/Documents/V2ray-Account/${google_account}/${ip} ]; then
		mkdir -p /Users/Jeff.Lin/Documents/V2ray-Account/${google_account}/${ip}
	fi
	local vmess="vmess://$(cat /usr/local/etc/v2ray/vmess_qr.json | base64 -b 0)"
	cat << EOF > /Users/Jeff.Lin/Documents/V2ray-Account/${google_account}/${ip}/config-${index}.txt	
------------- V2Ray 配置信息 -------------
 地址 (Address) = ${ip}
 端口 (Port) = ${port}
 用户ID (User ID / UUID) = ${v2ray_id}
 额外ID (Alter Id) = ${alter_id}
 传输协议 (Network) = tcp
 伪装类型 (header type) = none
------------------ END ------------------


---------- V2Ray vmess URL / V2RayNG v0.4.1+ / V2RayN v2.1+ / 仅适合部分客户端 -------------
${vmess}
EOF
}

export_qrcode()
{
	if [ ! -d /Users/Jeff.Lin/Documents/V2ray-Account/${google_account}/${ip} ]; then
		mkdir -p /Users/Jeff.Lin/Documents/V2ray-Account/${google_account}/${ip}
	fi

	local vmess="vmess://$(cat /usr/local/etc/v2ray/vmess_qr.json | base64 -b 0)"
	link="https://qrcode.online/img/?type=text&size=5&data=${vmess}"
	wget -O /Users/Jeff.Lin/Documents/V2ray-Account/${google_account}/${ip}/qrcode-${index}.png ${link}
}

create_v2ray_config
create_vmess_URL_config
if [ ! "${google_account}" == "test" ]
then
	scp_config
	export_config
	export_qrcode
fi
echo_v2ray_info

rm -rf /usr/local/etc/v2ray/vmess_qr.json
rm -rf /usr/local/etc/v2ray/config.json

