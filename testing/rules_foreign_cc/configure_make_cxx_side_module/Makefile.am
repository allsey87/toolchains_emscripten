all-local: libcxx_side_module_out.so

libcxx_side_module_out.so: cxx_side_module.o
	$(CXX) $(LDFLAGS) -shared -o $@ $^

cxx_side_module.o: src/test.cxx
	echo "CXX = $(CXX)"
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fPIC -c -o $@ $<

install-exec-local: libcxx_side_module_out.so
	@mkdir -p $(DESTDIR)$(libdir)
	install -m 0755 libcxx_side_module_out.so $(DESTDIR)$(libdir)/libcxx_side_module_out.so

clean-local:
	rm -f cxx_side_module.o libcxx_side_module_out.so

.PHONY: all-local install-exec-local clean-local