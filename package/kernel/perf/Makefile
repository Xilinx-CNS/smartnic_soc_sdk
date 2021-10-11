# build perf tools from KERNDIR

BUILD:=build

all:
	echo "Nothing added in all"

install:
	mkdir -p $(DESTDIR)/usr/bin
	cp -r $(BUILD)/etc $(DESTDIR)
	cp -r $(BUILD)/bin $(DESTDIR)/usr
	cp -r $(BUILD)/lib64 $(DESTDIR)/usr
	cp -r $(BUILD)/libexec $(DESTDIR)/usr
	cp -r $(BUILD)/share $(DESTDIR)/usr

