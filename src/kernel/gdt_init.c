// src/kernel/gdt_init.c

#include "include/kernel/vga_print.c"

typedef struct __attribute__((packed)) {
    unsigned short limit_low;      // Bits 0-15 of segment limit
    unsigned short base_low;       // Bits 0-15 of base address
    unsigned char  base_middle;    // Bits 16-23 of base
    unsigned char  access;         // Access byte
    unsigned char  granularity;    // Flags + bits 16-19 of limit
    unsigned char  base_high;      // Bits 24-31 of base
} gdt_entry;

typedef struct __attribute__((packed)) {
    unsigned short limit;  // Size of GDT - 1
    unsigned int   base;   // Address of first GDT entry
} gdt_ptr; 

#define GDT_ENTRIES 6
gdt_entry gdt[GDT_ENTRIES];
gdt_ptr gp;

gdt_entry gdt_create_entry(unsigned int base, unsigned int limit, unsigned char access, unsigned char granularity)
{
    gdt_entry entry;

    entry.base_low = base & 0xFFFF;
    entry.base_middle = (base >> 16) & 0xFF;
    entry.base_high = (base >> 24) & 0xFF;

    entry.limit_low = limit & 0xFFFF;
    entry.granularity = granularity | ((limit >> 16) & 0x0F);

    entry.access = access;

    return entry;
}

void gdt_init()
{
    // base gdt (necessary)
    gdt[0] = gdt_create_entry(0, 0, 0, 0);

    // kernel code + data
    gdt[1] = gdt_create_entry(0, 0xFFFFFF, 0b10011010, 0xCF); 
    gdt[2] = gdt_create_entry(0, 0xFFFFFF, 0b10010010, 0xCF); 

    // user code + data
    gdt[3] = gdt_create_entry(0, 0xFFFFFF, 0b11111010, 0xCF); 
    gdt[4] = gdt_create_entry(0, 0xFFFFFF, 0b11110010, 0xCF);

    // task state segment 
    gdt[5] = gdt_create_entry(0, 0xFFFFFF, 0b10001001, 0x00);

    gp.limit = (sizeof(gdt_entry) * GDT_ENTRIES) - 1;
    gp.base = (unsigned int)&gdt;

    asm volatile (
        "lgdt (%0)\n"         // gdt register -> address of gp
        "ljmp $0x08, $.1\n"   // reload code segment register with kernel code selector (index 1 in gdt)
        ".1:\n"
        "mov $0x10, %%ax\n"   // update all segment registers to 0x10 (kernel data segment)
        "mov %%ax, %%ds\n"    
        "mov %%ax, %%es\n"    
        "mov %%ax, %%fs\n"    
        "mov %%ax, %%gs\n"    
        "mov %%ax, %%ss\n"  
        "mov $0x28, %%ax\n" 
        "ltr %%ax\n"          // enable TSS
        : : "r"(&gp)
    );
}