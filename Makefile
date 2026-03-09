# Toolchain
		
AS = arm-linux-gnueabi-as		# ARM assembler
LD = arm-linux-gnueabi-ld		# AMR linker
QEMU = qemu-arm				# QEMU ARM user-mode

ASFLAGS = -g				# include debug symbols (for GDB)
LDFLAGS = -static			# statically link

TARGET = scheduler

$(TARGET): $(TARGET).o
	$(LD) $(LDFLAGS) -o $@ $^
	@echo "Built $(TARGET)"

$(TARGET).o: $(TARGET).s
	$(AS) $(ASFLAGS) -o $@ $<


# Run on QEMU user-mode
run: $(TARGET)
	$(QEMU) ./$(TARGET)

# Run WITH GDB
debug: $(TARGET)
	$(QEMU) -g 123 ./$(TARGET) &
	@echo "QEMU waiting for GDB on port 1234"

# Clean
clean:
	rm -f $(TARGET) $(TARGET).o
