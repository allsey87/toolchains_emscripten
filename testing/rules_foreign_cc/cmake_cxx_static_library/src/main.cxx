#include <iostream>
#include <stdexcept>

#include "test.h"

int main() {
    if(sum(41, 1) != 42) {
        throw std::runtime_error("Error adding numbers");
    }
    return 0;
}
