* Using CloudFlare's Argo tunnel, compatible with Json / token / temporary three-way authentication, using TLS encrypted communication, the application traffic can be safely transmitted to the Cloudflare network, improving the security and reliability of the application. In addition, Argo Tunnel can also prevent network threats such as IP leaks and DDoS attacks
* Unlock chatGPT
* View various information of the system in the browser, which is convenient and intuitive
* Integrate Nezha probe, you can freely choose whether to install it, support SSL/TLS mode, adapt to Nezha over Argo project: https://github.com/fscarmen2/Argo-Nezha-Service-Container
* uuid, WS path can be customized, or use the default value
* The front-end js timing and pm2 cooperate to keep alive, so as to minimize the recovery time
* Node information is output in the form of V2rayN / Clash / small rocket link
* You can use webssh and webftp with a browser, which is more convenient to manage the system
* Project path `https://github.com/fscarmen2/Render`

*Variables used by the PaaS platform
   | Variable name | Required | Default value | Remarks |
   | ------------ | ------ | ------ | ------ |
   | UUID | No | de04add9-5c68-8bab-950c-08cd5320df18 | Can be generated online https://www.zxgj.cn/g/uuid |
   | WSPATH | No | argo | Do not start with /, each protocol path is `/WSPATH-protocol`, such as `/argo-vless`, `/argo-vmess`, `/argo-trojan` |
   | NEZHA_SERVER | No | | The IP or domain name of the data communication between the Nezha probe and the panel server |
   | NEZHA_PORT | No | | The port of the Nezha probe server |
   | NEZHA_KEY | No | | Nezha Probe client dedicated Key |
   | NEZHA_TLS | No | | Whether the Nezha probe enables SSL/TLS encryption, if not enabled, do not need this variable, if you want to enable it, fill in "1" |
   | ARGO_AUTH | No | | Token or json value of Argo |
   | ARGO_DOMAIN | No | | Argo's domain name must be filled together with ARGO_DOMAIN to take effect |
   | WEB_USERNAME | No | admin | Username for web page |
   | WEB_PASSWORD | No | password | Web page password |
   | SSH_DOMAIN | No | | The domain name of webssh, username and password are <WEB_USERNAME> and <WEB_PASSWORD> |
   | FTP_DOMAIN | No | | webftp domain name, username and password are <WEB_USERNAME> and <WEB_PASSWORD> |

* path
   | command | description |
   | ---- |------ |
   | <URL>/list | View node data |
   | <URL>/status | View background processes |
   | <URL>/listen | View background listening port |
   | <URL>/test | Test if the system is read-only |


<img width="1011" alt="image" src="https://user-images.githubusercontent.com/92626977/215507678-ec03089e-4612-4cdc-880d-11470f64df0f.png">
<img width="1297" alt="image" src="https://user-images.githubusercontent.com/92626977/215507892-b50d7935-aa8b-4a28-8d35-7e6a3ca62621.png">
<img width="1405" alt="image" src="https://user-images.githubusercontent.com/92626977/215509099-fec65804-f9a9-4fa0-adff-25eee1ed6a75.png">
<img width="1287" alt="image" src="https://user-images.githubusercontent.com/92626977/215508740-c0e8d982-5351-4593-8b37-0f25bbde0eab.png">

* principle
```
+---------+     argo     +---------+     http     +--------+    ssh    +-----------+
| browser | <==========> | CF edge | <==========> |  ttyd  | <=======> | ssh server|
+---------+     argo     +---------+   websocket  +--------+    ssh    +-----------+

+---------+     argo     +---------+     http     +--------------+    ftp    +-----------+
| browser | <==========> | CF edge | <==========> | filebrowser  | <=======> | ftp server|
+---------+     argo     +---------+   websocket  +--------------+    ftp    +-----------+
```

* ttyd / filebrowser uses the tunnel built by Json
  
<img width="1643" alt="image" src="https://user-images.githubusercontent.com/92626977/235453084-a8c55417-18b4-4a47-9eef-ee3053564bff.png">
<img width="1347" alt="image" src="https://user-images.githubusercontent.com/92626977/235453394-2d8fd1e9-02d0-4fa6-8c20-dda903fd06ae.png">
<img width="983" alt="image" src="https://user-images.githubusercontent.com/92626977/235453962-1001bcb8-e21d-4c1b-9b8f-6161706f5ccd.png">
<img width="1540" alt="image" src="https://user-images.githubusercontent.com/92626977/235454653-3ac83b16-b6f4-477b-bccf-2cce8bcfbabe.png">