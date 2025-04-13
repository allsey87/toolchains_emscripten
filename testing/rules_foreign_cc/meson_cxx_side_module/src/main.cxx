#include <iostream>
#include <stdexcept>
#include <dlfcn.h>

typedef int (*fn_ptr)(int, int);

int main() {
    void* side_module = dlopen("cxx_side_module/lib/libcxx_side_module_out.so", RTLD_LAZY);
    if (!side_module) {
        const std::string& error_message =
            std::string("Error loading module: ") + dlerror();
        throw std::runtime_error(error_message);
    }
    dlerror();

    fn_ptr sum_fn = (fn_ptr)dlsym(side_module, "sum");
    const char* dlsym_error = dlerror();
    if (dlsym_error) {
        const std::string& error_message =
            std::string("Error getting symbol: ") + dlsym_error;
        throw std::runtime_error(error_message);
    }
    
    if(sum_fn(41, 1) != 42) {
        throw std::runtime_error("Error adding numbers");
    }
    
    dlclose(side_module);
    return 0;
}
