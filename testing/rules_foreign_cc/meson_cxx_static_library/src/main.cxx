#include <iostream>
#include <stdexcept>
#include <cstdlib>

#include "test.h"

int main() {
    if(sum(41, 1) != 42) {
        throw std::runtime_error("Error adding numbers");
    }
    return EXIT_SUCCESS;
}
