[TOC]

---
### &#10161; **Linux作为网关功能操作**
```
¥150
# 配置静态IP
wtt@wtt-virtual-machine:~Desktop$ sudo vi /etc/netplan/00-xx.yaml
    network:
      version: 2
      ethernets:
        ens160:
          dhcp4: false
          addresses: [192.168.244.5/24]
          gateway4: 192.168.244.2
          nameservers:
                  addresses: [114.114.114.114, 223.5.5.5]
wtt@wtt-virtual-machine:~Desktop$ sudo netplay apply

# 开启 ip_forward 功能
wtt@wtt-virtual-machine:~Desktop$ sudo vi /etc/sysctl.conf 
    net.ipv4.ip_forward = 1

# 使用 sysctl 配置生效
wtt@wtt-virtual-machine:~Desktop$ sudo sysctl -p

# 配置网关出口规则
wtt@wtt-virtual-machine:~Desktop$ sudo iptables -t nat -A POSTROUTING -s 192.168.244.0/24 -j MASQUERADE
```

### &#10161; **安装dhcp服务，配置mac和IP绑定**
```
# 安装dhcp服务软件
wtt@wtt-virtual-machine:~Desktop$ sudo apt install isc-dhcp-server

# 配置dhcp IPv4监听的本地网口号
wtt@wtt-virtual-machine:~Desktop$ sudo vi /etc/default/isc-dhcp-server
    INTERFACESv4="ens160"

# 配置dhcp IPv4分配的IP信息和静态IP配置
wtt@wtt-virtual-machine:~Desktop$ sudo vi /etc/dhcp/dhcpd.conf
    option domain-name "example.org";
    option domain-name-servers 114.114.114.114, 223.5.5.5;
    default-lease-time 600;
    max-lease-time 7200;
    ddns-update-style none;
    subnet 192.168.244.0 netmask 255.255.255.0 {
        range 192.168.244.100 192.168.244.150;
        option domain-name-servers 114.114.114.114, 1.2.4.8;
        option routers 192.168.244.5;
        option subnet-mask 255.255.255.0;
        option broadcast-address 192.168.244.255;
        default-lease-time 600;
        max-lease-time 7200;
    }
    host static_ip_1 {
        hardware ethernet 00:0c:29:0b:83:b6;
        fixed-address 192.168.244.200;
    }
    host static_ip_2 {
        hardware ethernet 11:11:29:0b:83:b8;
        fixed-address 192.168.244.211;
    }
    host static_ip_3 {
        hardware ethernet 33:33:29:0b:83:b8;
        fixed-address 192.168.244.233;
    }
    
wtt@wtt-virtual-machine:~Desktop$ sudo systemctl restart isc-dhcp-server
```
### &#10161; **iptables规则： ip过滤 port过滤**
```
# 默认都ACCEPT状态
wtt@wtt-virtual-machine:~Desktop$ sudo iptables -vnL
    Chain INPUT (policy ACCEPT 849K packets, 144M bytes)
     pkts bytes target     prot opt in     out     source               destination         
    
    Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
     pkts bytes target     prot opt in     out     source               destination         
    
    Chain OUTPUT (policy ACCEPT 455K packets, 69M bytes)
     pkts bytes target     prot opt in     out     source               destination

# 添加IP过滤规则: 禁止源IP为192.168.244.200数据包转发
wtt@wtt-virtual-machine:~Desktop$ sudo iptables -A FORWARD -s 192.168.244.200 -j REJECT

# 添加IP过滤规则: 禁止所有IP访问指定IP 192.168.200.200服务器
wtt@wtt-virtual-machine:~Desktop$ sudo iptables -A FORWARD -d 192.168.200.200 -j REJECT

# 添加PORT过滤规则: 禁止所有IP访问指定端口的业务
wtt@wtt-virtual-machine:~Desktop$ sudo iptables -A FORWARD -p tcp --dport 88 -j REJECT

# 添加PORT过滤规则: 禁止指定IP地址访问指定端口的业务
wtt@wtt-virtual-machine:~Desktop$ sudo iptables -A FORWARD -p tcp --dport 89 -s 192.168.244.200 -j REJECT

# 检查规则是否配置成功
wtt@wtt-virtual-machine:~Desktop$ sudo iptables -vnL FORWARD
    Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
     pkts bytes target     prot opt in     out     source               destination         
        0     0 REJECT     all  --  *      *       192.168.244.200      0.0.0.0/0            reject-with icmp-port-unreachable
        0     0 REJECT     all  --  *      *       0.0.0.0/0            192.168.200.200      reject-with icmp-port-unreachable
        0     0 REJECT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:88 reject-with icmp-port-unreachable
        0     0 REJECT     tcp  --  *      *       192.168.244.200      0.0.0.0/0            tcp dpt:89 reject-with icmp-port-unreachable
```
