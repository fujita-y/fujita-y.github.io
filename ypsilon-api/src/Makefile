# make distclean
# make -j0
# make install
# make clean
# make -j0
# make install

.PHONY : all clean install test distclean

TARGET_FILES = 	libref.ypsilon.c-types.html libref.ypsilon.socket.html

all: $(TARGET_FILES)
	@cp base.css ../base.css

clean:
	@rm -f $(TARGET_FILES)

distclean: clean
	@rm -f linkmap.dat

install: all
	@cp $(TARGET_FILES) ..
	@cp r6rs.html ..

test:
	open r6rs.html $(TARGET_FILES)

r6rs:
	ypsilon r6rsmake.scm | cat template/header-index.html - template/footer-index.html > r6rs.html

%.html : %.scm
	@echo 'processing $< -> $@'
	@ypsilon docmake.scm < $< | cat template/header.html - template/footer.html > $@
