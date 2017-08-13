obj-m:=tcp_scalable_re.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install:
	install tcp_scalable_re.ko /lib/modules/$(shell uname -r)/kernel/net/ipv4
	insmod /lib/modules/$(shell uname -r)/kernel/net/ipv4/tcp_scalable_re.ko
	depmod -a
	modprobe tcp_scalable_re