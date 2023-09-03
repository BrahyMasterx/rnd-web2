#!/usr/bin/env bash

# set variables
WSPATH=${WSPATH:-'argo'}
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
WEB_USERNAME=${WEB_USERNAME:-'admin'}
WEB_PASSWORD=${WEB_PASSWORD:-'password'}

generate_config() {
  cat > config.json << EOF
{
	"log": {
		"loglevel": "none"
	},
	"inbounds": [{
			"port": 8080,
			"protocol": "vless",
			"settings": {
				"clients": [{
					"id": "${UUID}"
				}],
				"decryption": "none",
				"fallbacks": [{
						"dest": 3001
					},
					{
						"path": "/${WSPATH}-vless",
						"dest": 3002
					},
					{
						"path": "/${WSPATH}-trojan",
						"dest": 3004
					}
				]
			},
			"streamSettings": {
				"network": "tcp"
			}
		},
		{
			"port": 3001,
			"listen": "127.0.0.1",
			"protocol": "vless",
			"settings": {
				"clients": [{
					"id": "${UUID}"
				}],
				"decryption": "none"
			},
			"streamSettings": {
				"network": "ws",
				"security": "none"
			}
		},
		{
			"port": 3002,
			"listen": "127.0.0.1",
			"protocol": "vless",
			"settings": {
				"clients": [{
					"id": "${UUID}"
				}],
				"decryption": "none"
			},
			"streamSettings": {
				"network": "ws",
				"security": "none",
				"wsSettings": {
					"path": "/${WSPATH}-vless"
				}
			},
			"sniffing": {
				"enabled": true,
				"destOverride": [
					"http",
					"tls"
				],
				"metadataOnly": false
			}
		},
		{
			"port": 3004,
			"listen": "127.0.0.1",
			"protocol": "trojan",
			"settings": {
				"clients": [{
					"password": "${UUID}"
				}]
			},
			"streamSettings": {
				"network": "ws",
				"security": "none",
				"wsSettings": {
					"path": "/${WSPATH}-trojan"
				}
			},
			"sniffing": {
				"enabled": true,
				"destOverride": [
					"http",
					"tls"
				],
				"metadataOnly": false
			}
		}

	],
	"dns": {
		"servers": [
			"https+local://8.8.8.8/dns-query"
		]
	},
	"outbounds": [{
			"protocol": "freedom"
		}

	]

}
EOF
}

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

argo_type() {
  if [[ -n "\${ARGO_AUTH}" && -n "\${ARGO_DOMAIN}" ]]; then
    [[ \$ARGO_AUTH =~ TunnelSecret ]] && echo \$ARGO_AUTH > tunnel.json && cat > tunnel.yml << EOF
tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)
credentials-file: /app/tunnel.json
protocol: http2

ingress:
  - hostname: \$ARGO_DOMAIN
    service: http://localhost:8080
EOF

    [ -n "\${SSH_DOMAIN}" ] && cat >> tunnel.yml << EOF
  - hostname: \$SSH_DOMAIN
    service: http://localhost:2222
EOF

    [ -n "\${FTP_DOMAIN}" ] && cat >> tunnel.yml << EOF
  - hostname: \$FTP_DOMAIN
    service: http://localhost:3333
EOF

    cat >> tunnel.yml << EOF
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF

  else
    ARGO_DOMAIN=\$(cat argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}

export_list() "

  cat > list << EOF
*******************************************
V2-rayN:
----------------------------
vless://${UUID}@unpkg.com:443?encryption=none&security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-vless?ed=2048#Argo-Vless
----------------------------
----------------------------
trojan://${UUID}@unpkg.com:443?security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-trojan?ed=2048#Argo-Trojan
*******************************************
small rocket:
----------------------------
vless://${UUID}@unpkg.com:443?encryption=none&security=tls&type=ws&host=\${ARGO_DOMAIN}&path=/${WSPATH}-vless?ed=2048&sni=\${ARGO_DOMAIN}#Argo-Vless
----------------------------
trojan://${UUID}@unpkg.com:443?peer=\${ARGO_DOMAIN}&plugin=obfs-local;obfs=websocket;obfs-host=\${ARGO_DOMAIN};obfs-uri=/${WSPATH}-trojan?ed=2048#Argo-Trojan
*******************************************
EOF
  cat list
}

argo_type
export_list
ABC
}

generate_nezha() {
  cat > nezha.sh << EOF
#!/usr/bin/env bash

# Check if running
check_run() {
  [[ \$(pgrep -lafx nezha-agent) ]] && echo "Nezha client is running" && exit
}

# If the three variables of Nezha are not complete, the Nezha client will not be installed
check_variable() {
  [[ -z "\${NEZHA_SERVER}" || -z "\${NEZHA_PORT}" || -z "\${NEZHA_KEY}" ]] && exit
}

# Download the latest version of Nezha Agent
download_agent() {
  if [ ! -e nezha-agent ]; then
    URL=\$(wget -qO- "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip")
    URL=\${URL:-https://github.com/naiba/nezha/releases/download/v0.14.11/nezha-agent_linux_amd64.zip}
    wget \${URL}
    unzip -qod ./ nezha-agent_linux_amd64.zip
    rm -f nezha-agent_linux_amd64.zip
  fi
}

check_run
check_variable
download_agent
EOF
}

generate_ttyd() {
  cat > ttyd.sh << EOF
#!/usr/bin/env bash

# Check if running
check_run() {
  [[ \$(pgrep -lafx ttyd) ]] && echo "ttyd is running" && exit
}

# If the ssh argo domain name is not set, ttyd will not be installed
check_variable() {
  [ -z "\${SSH_DOMAIN}" ] && exit
}

# Download the latest version of ttyd
download_ttyd() {
  if [ ! -e ttyd ]; then
    URL=\$(wget -qO- "https://api.github.com/repos/tsl0922/ttyd/releases/latest" | grep -o "https.*x86_64")
    URL=\${URL:-https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64}
    wget -O ttyd \${URL}
    chmod +x ttyd
  fi
}

check_run
check_variable
download_ttyd
EOF
}

generate_filebrowser () {
  cat > filebrowser.sh << EOF
#!/usr/bin/env bash

# Check if running
check_run() {
  [[ \$(pgrep -lafx filebrowser) ]] && echo "filebrowser running" && exit
}

# If the ftp argo domain name is not set, filebrowser will not be installed
check_variable() {
  [ -z "\${FTP_DOMAIN}" ] && exit
}

# download the latest version of filebrowser
download_filebrowser() {
  if [ ! -e filebrowser ]; then
    URL=\$(wget -qO- "https://api.github.com/repos/filebrowser/filebrowser/releases/latest" | grep -o "https.*linux-amd64.*gz")
    URL=\${URL:-https://github.com/filebrowser/filebrowser/releases/download/v2.23.0/linux-amd64-filebrowser.tar.gz}
    wget -O filebrowser.tar.gz \${URL}
    tar xzvf filebrowser.tar.gz filebrowser
    rm -f filebrowser.tar.gz
    chmod +x filebrowser
    PASSWORD_HASH=\$(./filebrowser hash \$WEB_PASSWORD)
    sed -i "s#PASSWORD_HASH#\$PASSWORD_HASH#g" ecosystem.config.js
  fi
}

check_run
check_variable
download_filebrowser
EOF
}

# Generate pm2 configuration file
generate_pm2_file() {
  if [[ -n "${ARGO_AUTH}" && -n "${ARGO_DOMAIN}" ]]; then
    [[ $ARGO_AUTH =~ TunnelSecret ]] && ARGO_ARGS="tunnel --edge-ip-version auto --config tunnel.yml run"
    [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]] && ARGO_ARGS="tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH}"
  else
    ARGO_ARGS="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile argo.log --loglevel info --url http://localhost:8080"
  fi

  TLS=${NEZHA_TLS:+'--tls'}

  cat > ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"/app/web.js run"
      },
      {
          "name":"argo",
          "script":"cloudflared",
          "args":"${ARGO_ARGS}"
EOF

  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_PORT}" && -n "${NEZHA_KEY}" ]] && cat >> ecosystem.config.js << EOF
      },
      {
          "name":"nezha",
          "script":"/app/nezha-agent",
          "args":"-s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS}"
EOF
  
  [ -n "${SSH_DOMAIN}" ] && cat >> ecosystem.config.js << EOF
      },
      {
          "name":"ttyd",
          "script":"/app/ttyd",
          "args":"-c ${WEB_USERNAME}:${WEB_PASSWORD} -p 2222 bash"
EOF

  [ -n "${FTP_DOMAIN}" ] && cat >> ecosystem.config.js << EOF
      },
      {
          "name":"filebrowser",
          "script":"/app/filebrowser",
          "args":"--port 3333 --username ${WEB_USERNAME} --password 'PASSWORD_HASH'"
EOF

  cat >> ecosystem.config.js << EOF
      }
  ]
}
EOF
}

generate_config
generate_argo
generate_nezha
generate_ttyd
generate_filebrowser
generate_pm2_file

[ -e nezha.sh ] && bash nezha.sh
[ -e argo.sh ] && bash argo.sh
[ -e ttyd.sh ] && bash ttyd.sh
[ -e filebrowser.sh ] && bash filebrowser.sh
[ -e ecosystem.config.js ] && pm2 start
