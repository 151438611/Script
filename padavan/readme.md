### 编译Padavan学习记录

```
Debian 10示例:
# 1 安装依赖
apt upgrade
apt install autoconf automake autopoint bison build-essential flex gawk gettext git gperf libtool pkg-config zlib1g-dev libgmp3-dev libmpc-dev libmpfr-dev texinfo python-docutils git

# 2 下载padavan源代码
cd /opt && git clone https://bitbucket.org/padavan/rt-n56u.git

# 3 构建编译toolchain-mipsel工具链
cd /opt/rt-n56u/toolchain-mipsel
./clean_sources
./build_toolchain

# 4 修改配置文件适应指定型号路由器设备
# 4.1 修改trunk/.config配置,添加或删除系统软件或功能; 以K2示例(因K2无USB,关闭USB的相关设置)
cd /opt/rt-n56u/trunk
cp configs/templates/ac54u_base.config .config
vi .config
  CONFIG_VENDOR=Ralink
  CONFIG_PRODUCT=MT7620
  CONFIG_FIRMWARE_PRODUCT_ID="RT-AC54U"
  CONFIG_LINUXDIR=linux-3.4.x
  CONFIG_TOOLCHAIN_DIR=/opt/rt-n56u/toolchain-mipsel
  CONFIG_FIRMWARE_CPU_600MHZ=y
  #CONFIG_FIRMWARE_CPU_SLEEP=y
  #CONFIG_FIRMWARE_ENABLE_USB=y
  CONFIG_FIRMWARE_ENABLE_EXT4=y
  CONFIG_FIRMWARE_INCLUDE_NFSC=y
  CONFIG_FIRMWARE_INCLUDE_CIFS=y
  CONFIG_FIRMWARE_INCLUDE_DROPBEAR=y
  ...
vi configs/boards/RT-AC54U/board.mk
  BOARD_NUM_USB_PORTS=0
# 4.2 修改GPIO定义
vi configs/boards/RT-AC54U/board.h
  #define BOARD_BOOT_TIME		25
  #define BOARD_FLASH_TIME	120
  #define BOARD_GPIO_BTN_RESET	1
  #define BOARD_GPIO_BTN_WPS	1
  #define BOARD_GPIO_LED_ALL	10
  #undef  BOARD_GPIO_LED_WIFI     11
  #define BOARD_GPIO_LED_POWER	8
  #undef  BOARD_GPIO_LED_LAN
  #undef  BOARD_GPIO_LED_WAN	10
  #define BOARD_GPIO_LED_USB	14
  ...
# 4.3 修改kernel内核配置
vi configs/boards/RT-AC54U/kernel-3.4.x.config
  CONFIG_RALINK_MT7620=y
  CONFIG_RT2880_DRAM_64M=y
  CONFIG_RALINK_RAM_SIZE=64
  CONFIG_RT2880_FLASH_AUTO=y
  CONFIG_RT2880_UART_57600=y
  CONFIG_RALINK_UART_BRATE=57600
  CONFIG_RAETH_ESW_PORT_WAN=4
  CONFIG_RAETH_ESW_PORT_LAN1=3
  CONFIG_RAETH_ESW_PORT_LAN2=2
  CONFIG_RAETH_ESW_PORT_LAN3=1
  CONFIG_RAETH_ESW_PORT_LAN4=0
  ...
# 4.4 修改路由器系统参数
vi user/shared/defaults.h
  #define SYS_USER_ROOT           "admin"
  #define DEF_LAN_ADDR            "192.168.5.1"
  #define DEF_LAN_DHCP_BEG        "192.168.5.2"
  #define DEF_LAN_DHCP_END        "192.168.5.244"
  #define DEF_LAN_MASK            "255.255.255.0"
  #define DEF_WLAN_2G_CC          "CN"
  #define DEF_WLAN_5G_CC          "CN"
  #define DEF_WLAN_2G_SSID        "ASUS_24G"
  #define DEF_WLAN_5G_SSID        "ASUS_5G"
  #define DEF_WLAN_2G_GSSID       "ASUS_GUEST_24G"
  #define DEF_WLAN_5G_GSSID       "ASUS_GUEST_5G"
  #define DEF_WLAN_2G_PSK         "1234567890"
  #define DEF_WLAN_5G_PSK         "1234567890"
  #define DEF_ROOT_PASSWORD       "admin"
  #define DEF_TIMEZONE            "CST-8"
  #define DEF_NTP_SERVER0         "ntp.aliyun.com"
  ...
vi user/shared/defaults.c
  { "ntp_period", "48" },
  { "di_addr0", "114.114.114.114" },
  { "di_addr1", "8.8.8.8" },
  { "di_addr2", "" },
  { "di_addr3", "" },
  { "di_addr4", " },
  { "di_addr5", "" },
  { "di_port0", "53" },
  { "di_port1", "53" },
  { "di_port2", "" },
  { "di_port3", "" },
  { "di_port4", "" },
  { "di_port5", "" },
  { "telnetd", "0" },
  { "sshd_enable", "1" },
  ...
# 4.5 添加中文语言
  将CN.dict下载到trunk/user/www/dict; 并重命名为RU.dict
  mv CN.dict RU.dict
  vi trunk/user/www/Makefile
    echo "LANG_RU=简体中文" >> $(ROMFS_DIR)/www/EN.header
    ...
    
# 5 配置完,开始编码生成固件
cd /opt/rt-n56u/trunk
./clear_tree
./build_firmware
# 6 编码完成的固件在此目录下 /opt/rt-n56u/trunk/images  
```
