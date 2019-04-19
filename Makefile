FIRMWARE = firmware/
BOARD = esp01
all: check

check: checkprogsize
flash: upload uploadfs

checkprogsize upload buildfs uploadfs monitor:
	pio run -d $(FIRMWARE) -e $(BOARD) -t $@