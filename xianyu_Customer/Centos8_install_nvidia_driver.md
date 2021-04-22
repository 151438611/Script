### &#10161; **闲鱼客户: Centos8 编译安装NVIDIA RTX2080-TI显卡、CUDA驱动、nvidia-docker2**
```
一、安装显卡驱动
    官方文档: https://www.nvidia.com/Download/index.aspx?lang=cn
    1、安装依赖
        dnf install kernel-devel kernel-headers make gcc-c++ dkms libvdpau binutils
        # dnf install libglvnd-devel elfutils-libelf-devel
        注意: kernel-devel和kernel-headers版本需要和系统内核kernel版本(uname -a)一致
        注意: dkms在epel源中
        Ubuntu 18中命令： apt install g++ make
    2、禁用nouveau模块,重新建立initramfs image文件
        Linux系统默认安装的是开源的nouvea显卡驱动，它与nvidia显卡驱动冲突，所以装nvidia必须禁用nouvea模块！
        其次nvidia驱动默认安装OpenGL，这又与GNOME冲突，为了不让系统崩也要禁用nvidia驱动的OpenGL
        echo -e "blacklist nouveau\noptions nouveau modeset=0" > /etc/modprobe.d/blacklist.conf
        #vi /etc/default/grub                                                       # 可先不用操作此步
        #    GRUB_CMDLINE_LINUX="rd.driver.blacklist nouveau nouveau.modeset=0"     # 在命令后面添加:nouveau.modeset=0
        #grub2-mkconfig -o /boot/grub2/grub.cfg
        mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
        dracut /boot/initramfs-$(uname -r).img $(uname -r)                          # Ubuntu 18命令是：update-initramfs -u
        reboot
        lsmod | grep nouveau                                                        # 若没有任何输出说明禁用 nouveau 驱动成功
    3、下载驱动,并安装 
        下载地址: https://www.nvidia.cn/Download/index.aspx?lang=cn
        lspci -vnn | grep -i vga                                                    # 查看pcie显示卡信息
        lspci -v -s 01:00.0                                                         # 查看指定pcie设备详细系统
        wget https://us.download.nvidia.cn/XFree86/Linux-x86_64/440.100/NVIDIA-Linux-x86_64-440.100.run
        chmod +x NVIDIA-Linux-x86_64-440.100.run
        init 3                                                                      # 关闭图形界面,进入命令行模式;(Ubuntu需要按Ctrl+Alt+F1才能进入登陆界面)等安装驱动后重新再进入图形界面
        ./NVIDIA-Linux-x86_64-440.100.run --kernel-source-path=/usr/src/kernels/4.18.0-193.el8.x86_64 -no-opengl-files –no-x-check –no-nouveau-check
            # 必须添加 --no-opengl-files (只安装驱动文件,不安装OpenGL文件) 选项, 否则会login loop(循环登录)
            # 注册dkms时选项"Yes",可选"No"
            # 如果提示安装32位的兼容库，选"No"
            # 自动更新Xorg配置文件时,选择"Yes"
            # Ubuntu 18 中运行： ./NVIDIA-Linux-x86_64-440.100.run -no-opengl-files –no-x-check –no-nouveau-check
            
        reboot                                                                      # 安装完成后建议重启
        nvidia-smi                                                                  # 使用此命令输出显卡信息,则表示安装成功
        init 5                                                                      # 进入图形界面
        prime-select nvidia                                                         # 切换到nvidia显卡; 每一次切换显卡都需要重新启动电脑才能生效
        prime-select intel                                                          # 切换到intel显卡
        prime-select query                                                          # 查看当前使用的显卡
    4、问题记录:
        4.1、Error：Unable to load the 'nvidia-drm' kernel module .
            解决方法: 关闭主板BIOS的 Security boot 选项
        4.2、GDM无法登陆,并黑屏
            解决方法: systemctl restart systemd-logind
        注意: 编译安装的驱动程序,禁止升级系统内核及内核模块; 若需要升级新内核则需要重新编译
        参考文档: https://linuxconfig.org/how-to-install-the-nvidia-drivers-on-centos-8
            https://askubuntu.com/questions/1023036/how-to-install-nvidia-driver-with-secure-boot-enabled
            https://blog.csdn.net/qq_32656561/article/details/103936146?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.nonecase&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.nonecase
            https://blog.csdn.net/qq_32656561/article/details/105408917
            https://wizyoung.github.io/Ubuntu%E4%B8%8BGTX1080%E6%98%BE%E5%8D%A1%E9%A9%B1%E5%8A%A8%E6%8A%98%E8%85%BE%E5%B0%8F%E8%AE%B0/
    
二、安装CUDA驱动(包含nvidia驱动,不需要单独安装nvidia驱动): https://developer.nvidia.com/cuda-downloads
    # 20200629 CUDA Toolkit 11.0 RC仅有测试版本, 建议安装CUDA Toolkit 10.2正式版
    # cuda大小2.5G,在Linux中wget/curl下载速率较慢,建议使用Windows下载软件更快
    init 3
    wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run
    chmod +x cuda_10.2.89_440.33.01_linux.run
    ./cuda_10.2.89_440.33.01_linux.run --no-opengl-libs         # 可不用重新安装nvida驱动
    vi /etc/profile                                             # 最下面添加二行
        export PATH=/usr/local/cuda/bin:$PATH
        export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
    source /etc/profile
    nvcc --version                                              # 测试是否安装成功

三、安装nvidia-docker2:
    # 首先安装docker
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    wget https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.13-3.2.el7.x86_64.rpm     # 需要依赖 containerd.io
    dnf install containerd.io-1.2.13-3.2.el7.x86_64.rpm
    dnf clean all 
    dnf install docker-ce
    systemctl restart docker
    docker version                                              # 检测docker是否安装成功
    systemctl enable docker
    
    # 安装nvidia-docker2 : https://nvidia.github.io/nvidia-docker/
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | tee /etc/yum.repos.d/nvidia-docker.repo
    dnf clean all
    dnf install nvidia-docker2
    nvidia-docker version                                       # 检测nvidia-docker是否安装成功
    systemctl restart docker 

    问题一: /bin/nvidia-docker: line 34: /bin/docker: Permission denied
        解决方法：Selinux=disable
```

