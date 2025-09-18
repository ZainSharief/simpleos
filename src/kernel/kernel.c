// src/kernel/kernel.c

#include "include/kernel/vga_print.c"

__attribute__((section(".text.kernel_main")))
void kernel_main()
{
    volatile const char* kernel_msg = "Kernel Loaded!";
    vga_print(kernel_msg, 0, 0);

    for(;;);
}