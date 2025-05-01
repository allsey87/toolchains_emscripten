#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

typedef int (*fn_ptr)(int, int);

int main() {
    void* side_module = dlopen("libc_side_module.so", RTLD_LAZY);
    if (!side_module) {
        fprintf(stderr, "Error loading module: %s\n", dlerror());
        return EXIT_FAILURE;
    }
    dlerror();

    fn_ptr sum_fn = (fn_ptr)dlsym(side_module, "sum");
    const char* dlsym_error = dlerror();
    if (dlsym_error) {
        fprintf(stderr, "Error getting symbol: %s\n", dlsym_error);
        dlclose(side_module);
        return EXIT_FAILURE;
    }
    
    if (sum_fn(41, 1) != 42) {
        fprintf(stderr, "Error adding numbers\n");
        dlclose(side_module);
        return EXIT_FAILURE;
    }
    
    dlclose(side_module);
    return EXIT_SUCCESS;
}
