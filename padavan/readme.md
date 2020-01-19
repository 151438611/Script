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
  #CONFIG_FIRMWARE_ENABLE_USB=y
  CONFIG_FIRMWARE_ENABLE_EXT4=y
  CONFIG_FIRMWARE_INCLUDE_NFSC=y
  CONFIG_FIRMWARE_INCLUDE_CIFS=y
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
  CONFIG_RALINK_UART_BRATE=57600
  CONFIG_RAETH_ESW_PORT_WAN=4
  CONFIG_RAETH_ESW_PORT_LAN1=3
  CONFIG_RAETH_ESW_PORT_LAN2=2
  CONFIG_RAETH_ESW_PORT_LAN3=1
  CONFIG_RAETH_ESW_PORT_LAN4=0
  ...
  
# 5 配置完,开始编码生成固件
cd /opt/rt-n56u/trunk
./clear_tree
./build_firmware

```
