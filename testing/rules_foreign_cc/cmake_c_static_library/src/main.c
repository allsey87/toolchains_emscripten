#include <stdio.h>
#include <stdlib.h>

#include "test.h"

int main() {
    if (sum(41, 1) != 42) {
        fprintf(stderr, "Error adding numbers\n");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
