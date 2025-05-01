all-local: libc_side_module_out.so

libc_side_module_out.so: c_side_module.o
	$(CC) $(LDFLAGS) -shared -o $@ $^

c_side_module.o: src/test.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -c -o $@ $<

install-exec-local: libc_side_module_out.so
	@mkdir -p $(DESTDIR)$(libdir)
	install -m 0755 libc_side_module_out.so $(DESTDIR)$(libdir)/libc_side_module_out.so

clean-local:
	rm -f c_side_module.o libc_side_module_out.so

.PHONY: all-local install-exec-local clean-local