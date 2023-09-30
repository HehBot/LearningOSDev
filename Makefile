ASM := i386-elf-as
CC := i386-elf-gcc
LD := i386-elf-ld

EMU := qemu-system-i386
GDB := gdb

NAME := aos
SRC_DIR := src
INITRD_DIR := initrd
FS_DIR := user
BUILD_DIR := build

SRCS := $(shell find $(SRC_DIR) -name "*.c" -or -name "*.S")
DEPS := $(SRCS:%=$(BUILD_DIR)/%.d)
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

KERNEL_ELF := $(BUILD_DIR)/$(NAME).elf
DISK := $(BUILD_DIR)/$(NAME).iso
INITRD_IMG := $(INITRD_DIR)/initrd.img
FS_IMG := $(FS_DIR)/fs.img

INC_FLAGS = -I$(SRC_DIR)/ -I$(SRC_DIR)/util -I$(SRC_DIR)/util/liballoc

ASMFLAGS := -c -g
CFLAGS := -c -g -Wall -Wextra -Werror -ffreestanding -nostdlib -MMD -MP $(INC_FLAGS)
LDFLAGS := -T linker.ld

EMU_FLAGS := -no-reboot -no-shutdown -drive file=$(DISK),index=0,media=disk,format=raw -drive file=$(FS_IMG),index=1,media=disk,format=raw

run: $(DISK) $(FS_IMG)
	$(EMU) $(EMU_FLAGS)

debug: $(DISK) $(KERNEL_ELF) $(FS_IMG)
	$(EMU) -s -S $(EMU_FLAGS) &
	$(GDB) -ex "target remote tcp::1234" -ex "symbol-file $(KERNEL_ELF)"

disk: $(DISK)

$(DISK): $(KERNEL_ELF) $(INITRD_IMG) grub.cfg
	@mkdir -p $(dir $@)
	@mkdir -p iso/boot/grub
	cp $(KERNEL_ELF) iso/boot/$(NAME).elf
	cp $(INITRD_IMG) iso/boot/initrd.img
	cp grub.cfg iso/boot/grub/grub.cfg
	grub-mkrescue -o $@ iso

$(INITRD_IMG): .FORCE
	@$(MAKE) -C $(INITRD_DIR)

$(FS_IMG): .FORCE
	@$(MAKE) -C $(FS_DIR)

$(KERNEL_ELF): $(OBJS) linker.ld
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(BUILD_DIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/%.S.o: %.S
	@mkdir -p $(dir $@)
	@i386-elf-cpp -MMD -MP $(INC_FLAGS) -o $(BUILD_DIR)/$<.S $<
	$(ASM) $(ASMFLAGS) -o $@ $(BUILD_DIR)/$<.S
	@$(RM) $(BUILD_DIR)/$<.S

#####################################

clean:
	$(RM) -r $(BUILD_DIR) iso
	$(MAKE) -C $(INITRD_DIR) clean
	$(MAKE) -C $(FS_DIR) clean

.FORCE:
.PHONY: run debug disk clean

-include $(DEPS)
