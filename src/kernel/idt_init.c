// src/kernel/idt_init.c

#include "include/kernel/vga_print.c"

typedef struct __attribute__((packed)){
    unsigned short offset_low;   // bits 0-15 of handler function address
    unsigned short selector;     // kernel code segment selector in GDT
    unsigned char  zero;         // reserved, always 0
    unsigned char  type_attr;    // type and attributes
    unsigned short offset_high;  // bits 16-31 of handler function address
} idt_entry;

typedef struct __attribute__((packed)){
    unsigned short limit;  // Size of the IDT - 1
    unsigned int base;     // Address of the IDT
} idtr;

#define DEFINE_ISR(num) \
__attribute__((naked)) void isr##num()\
{ \
    asm volatile( \
        "pushl $0\n" \
        "pushl $" #num "\n" \
        "pusha\n" \
        "call isr" #num "_handler\n" \
        "popa\n" \
        "addl $8, %esp\n" \
        "iret\n" \
    ); \
}

#define DEFINE_ISR_ERRCODE(num) \
__attribute__((naked)) void isr##num()\
{ \
    asm volatile( \
        "pushl $" #num "\n" \
        "pusha\n" \
        "call isr" #num "_handler\n" \
        "popa\n" \
        "addl $8, %esp\n" \
        "iret\n" \
    ); \
}

static inline void outb(unsigned short port, unsigned char val) 
{ 
    __asm__ volatile ("outb %0, %1" :: "a"(val), "Nd"(port)); 
}

DEFINE_ISR(0)
DEFINE_ISR(1)
DEFINE_ISR(2)
DEFINE_ISR(3)
DEFINE_ISR(4)
DEFINE_ISR(5)
DEFINE_ISR(6)
DEFINE_ISR(7)
DEFINE_ISR_ERRCODE(8)
DEFINE_ISR(9)
DEFINE_ISR_ERRCODE(10)
DEFINE_ISR_ERRCODE(11)
DEFINE_ISR_ERRCODE(12)
DEFINE_ISR_ERRCODE(13)
DEFINE_ISR_ERRCODE(14)
DEFINE_ISR(15)
DEFINE_ISR(16)
DEFINE_ISR_ERRCODE(17)
DEFINE_ISR(18)
DEFINE_ISR(19)
DEFINE_ISR(20)
DEFINE_ISR_ERRCODE(21)
DEFINE_ISR(22)
DEFINE_ISR(23)
DEFINE_ISR(24)
DEFINE_ISR(25)
DEFINE_ISR(26)
DEFINE_ISR(27)
DEFINE_ISR(28)
DEFINE_ISR_ERRCODE(29)
DEFINE_ISR_ERRCODE(30)
DEFINE_ISR(31)

void isr0_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '0'; vga[1] = 0x07;}
void isr1_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07;}
void isr2_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07;}
void isr3_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '3'; vga[1] = 0x07;}
void isr4_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '4'; vga[1] = 0x07;}
void isr5_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '5'; vga[1] = 0x07;}
void isr6_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '6'; vga[1] = 0x07;}
void isr7_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '7'; vga[1] = 0x07;}
void isr8_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '8'; vga[1] = 0x07;}
void isr9_handler()  {volatile char* vga = (volatile char*)0xB8000; vga[0] = '9'; vga[1] = 0x07;}
void isr10_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '0'; vga[3] = 0x07;}
void isr11_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '1'; vga[3] = 0x07;}
void isr12_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '2'; vga[3] = 0x07;}
void isr13_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '3'; vga[3] = 0x07;}
void isr14_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '4'; vga[3] = 0x07;}
void isr15_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '5'; vga[3] = 0x07;}
void isr16_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '6'; vga[3] = 0x07;}
void isr17_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '7'; vga[3] = 0x07;}
void isr18_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '8'; vga[3] = 0x07;}
void isr19_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '1'; vga[1] = 0x07; vga[2] = '9'; vga[3] = 0x07;}
void isr20_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '0'; vga[3] = 0x07;}
void isr21_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '1'; vga[3] = 0x07;}
void isr22_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '2'; vga[3] = 0x07;}
void isr23_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '3'; vga[3] = 0x07;}
void isr24_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '4'; vga[3] = 0x07;}
void isr25_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '5'; vga[3] = 0x07;}
void isr26_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '6'; vga[3] = 0x07;}
void isr27_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '7'; vga[3] = 0x07;}
void isr28_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '8'; vga[3] = 0x07;}
void isr29_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '2'; vga[1] = 0x07; vga[2] = '9'; vga[3] = 0x07;}
void isr30_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '3'; vga[1] = 0x07; vga[2] = '0'; vga[3] = 0x07;}
void isr31_handler() {volatile char* vga = (volatile char*)0xB8000; vga[0] = '3'; vga[1] = 0x07; vga[2] = '1'; vga[3] = 0x07;}

void idt_set_gate(idt_entry* entry, unsigned int handler, unsigned short selector, unsigned char type_attr);

#define IDT_ENTRIES 256
#define CPU_EXCEPTIONS 32

void idt_init()
{
    //reprogram the PIC
    outb(0x0020, 0x11);
	outb(0x00A0, 0x11);

	//icw2
	outb(0x0021, 0x20);
	outb(0x00A1, 0x28);

	//icw3
	outb(0x0021, 0x04);
	outb(0x00A1, 0x02);

	//icw4
	outb(0x0021, 0x01);
	outb(0x00A1, 0x01);

    // prevents interrupts (32-47) from firing.
    outb(0x0021, 0xFF);
    outb(0x00A1, 0xFF);

    static idt_entry idt[IDT_ENTRIES];
    static idtr idt_ptr;
    
    for (int i = 0; i < IDT_ENTRIES; i++) {
        idt[i].offset_low = 0;
        idt[i].selector = 0;
        idt[i].zero = 0;
        idt[i].type_attr = 0;
        idt[i].offset_high = 0;
    }

    unsigned int isr[CPU_EXCEPTIONS] = {
        (unsigned int)isr0,  (unsigned int)isr1,  (unsigned int)isr2,  (unsigned int)isr3,
        (unsigned int)isr4,  (unsigned int)isr5,  (unsigned int)isr6,  (unsigned int)isr7,
        (unsigned int)isr8,  (unsigned int)isr9,  (unsigned int)isr10, (unsigned int)isr11,
        (unsigned int)isr12, (unsigned int)isr13, (unsigned int)isr14, (unsigned int)isr15,
        (unsigned int)isr16, (unsigned int)isr17, (unsigned int)isr18, (unsigned int)isr19,
        (unsigned int)isr20, (unsigned int)isr21, (unsigned int)isr22, (unsigned int)isr23,
        (unsigned int)isr24, (unsigned int)isr25, (unsigned int)isr26, (unsigned int)isr27,
        (unsigned int)isr28, (unsigned int)isr29, (unsigned int)isr30, (unsigned int)isr31
    };

    for (int i = 0; i < CPU_EXCEPTIONS; i++)
        idt_set_gate(&idt[i], isr[i], 0x08, 0x8E);

    idt_ptr.limit = sizeof(idt) - 1;
    idt_ptr.base  = (unsigned int)&idt;

    asm volatile ("lidt %0" : : "m"(idt_ptr));
    asm volatile("sti"); 

    volatile int x = 1;
    volatile int y = 0;
    volatile int z = x / y;

    return; 
}

void idt_set_gate(idt_entry* entry, unsigned int handler, unsigned short selector, unsigned char type_attr)
{
    entry->offset_low = handler & 0xFFFF;
    entry->selector   = selector;
    entry->zero       = 0;
    entry->type_attr  = type_attr;
    entry->offset_high = (handler >> 16) & 0xFFFF;
}