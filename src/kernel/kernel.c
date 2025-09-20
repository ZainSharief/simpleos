// src/kernel/kernel.c

#include "include/kernel/vga_print.c"
#include "src/kernel/gdt_init.c"

__attribute__((section(".text.kernel_main")))
void kernel_main()
{
    volatile const char* kernel_msg = "Kernel Loaded!";
    vga_print(kernel_msg, 0, 0);

    gdt_init();

    for(;;);
}