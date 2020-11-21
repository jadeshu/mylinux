BUILD_DIR = ./build
ENTRY_POINT = 0X0
AS = nasm
CC = gcc
LD = ld
DD = dd
LIB = -I lib/ -I mm/  -I kernel/
ASFLAGS = -f elf
# ASFLAGS2 = -f bin
CFLAGS = -Wall $(LIB) -c -fno-builtin -W -Wstrict-prototypes \
         -Wmissing-prototypes 
LDFLAGS = -Ttext $(ENTRY_POINT) -e startup_32 -Map $(BUILD_DIR)/kernel.map

# System environment variable.
ifeq ($(OS),Windows_NT)
	HOSTOS		:= windows
else
	ifeq ($(shell uname),Darwin)
		HOSTOS		:= macos
	else
		ifeq ($(shell uname),Linux)
			HOSTOS		:= linux
		else
			HOSTOS		:= unix-like
		endif
	endif
endif

# virtual machine
BOCHS 		= bochs
QEMU 		= qemu-system-i386

# debugger
BOCHSDBG 	= bochsdbg

# development dir
DEVELOPMENT_DIR	= ../developments
# boot dir
ARCH_BOOT_DIR = ./boot

# bochs development dir
BOCHS_DIR = $(DEVELOPMENT_DIR)/bochs

# bochsrc for windows
BXRC_WIN 		= $(BOCHS_DIR)/bochsrc.win
# bochsrc for linux
BXRC_LINUX 		= $(BOCHS_DIR)/bochsrc.linux

#boot temp file
MBR_BIN =  $(ARCH_BOOT_DIR)/boot.bin
LOADER_BIN =  $(ARCH_BOOT_DIR)/loader.bin

#loader disk
LOADER_OFF = 2		
LOADER_CNTS = 6
#system disk
SYS_OFF = 10
SYS_CNTS = 80	

#----img----
#img dir
IMG_DIR = $(DEVELOPMENT_DIR)/image
FLAPPY_IMG 	= $(IMG_DIR)/boot.img

#obj
OBJS =  $(BUILD_DIR)/head.o  $(BUILD_DIR)/main.o $(BUILD_DIR)/print.o  \
		$(BUILD_DIR)/memory.o

all: mk_dir  bochs

##############     c代码编译     ###############
$(BUILD_DIR)/main.o:  kernel/main.c
	$(CC) $(CFLAGS) $< -o $@ 

$(BUILD_DIR)/memory.o: mm/memory.c
	$(CC) $(CFLAGS) $< -o $@
##############    汇编代码编译    ################
# $(ARCH_BOOT_DIR)/boot.bin: boot/const.inc boot/boot.S
# 	$(AS) $(ASFLAGS2)  $< -o $@
# $(ARCH_BOOT_DIR)/loader.bin: boot/const.inc boot/loader.S 
# 	$(AS) $(ASFLAGS2)  $< -o $@
	
$(BUILD_DIR)/head.o: kernel/head.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD_DIR)/print.o: kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@

##############    链接所有目标文件    #############
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

$(BUILD_DIR)/system.bin: $(BUILD_DIR)/kernel.bin
	objcopy -I elf32-i386 -S -R ".eh_frame" -R ".comment" -O binary $(BUILD_DIR)/kernel.bin  $(BUILD_DIR)/system.bin
############## ############## ############## ############## 
.PHONY : mk_dir

mk_dir:
	if [[ ! -d $(BUILD_DIR) ]];then mkdir $(BUILD_DIR);fi

disk: $(MBR_BIN) $(LOADER_BIN)  $(BUILD_DIR)/system.bin
	$(DD) if=$(MBR_BIN) of=$(FLAPPY_IMG) bs=512 count=1 conv=notrunc
	$(DD) if=$(LOADER_BIN) of=$(FLAPPY_IMG) bs=512 seek=$(LOADER_OFF) count=$(LOADER_CNTS) conv=notrunc
	$(DD) if=$(BUILD_DIR)/system.bin of=$(FLAPPY_IMG) bs=512 seek=$(SYS_OFF) count=$(SYS_CNTS) conv=notrunc

bochs: disk
ifeq ($(HOSTOS),windows)
	$(BOCHS) -q -f $(BXRC_WIN)
else
	$(BOCHS) -q -f $(BXRC_LINUX)
endif

bochsdbg: disk
ifeq ($(HOSTOS),windows)
	$(BOCHSDBG) -q -f $(BXRC_WIN)
else
	$(BOCHSDBG) -q -f $(BXRC_LINUX)
endif


#-hda $(HDA_IMG) -hdb $(HDB_IMG)
# 网卡配置: 
#	-net nic,vlan=0,model=rtl8139,macaddr=12:34:56:78:9a:be
# 网络模式：
#	1.User mode network(Slirp) :User网络
#		-net user
#	2.Tap/tun network : Tap网络
#		-net tap
# 		-net tap,vlan=0,ifname=tap0
#	example: -net nic,model=rtl8139 -net tap,ifname=tap0,script=no,downscript=no 
		
# 音频配置：
# 	a.使用蜂鸣器：-soundhw pcspk
#	b.使用声霸卡：-soundhw sb16
# 控制台串口调试： -serial stdio 
QEMU_ARGUMENT = -m 256M \
		-name "XBook Development Platform for x86" \
		-fda $(FLAPPY_IMG) -hda $(HDC_IMG) -hdb $(HDD_IMG) -boot a \
		-serial stdio
		
qemu: disk
	$(QEMU) $(QEMU_ARGUMENT)

# 调试配置：-S -gdb tcp::10001,ipv4
qemudbg: disk
	$(QEMU) -S -gdb tcp::10001,ipv4 $(QEMU_ARGUMENT)
	
clean:
	cd $(BUILD_DIR) && rm -f ./*
	cd $(IMG_DIR) && rm -f ./*

