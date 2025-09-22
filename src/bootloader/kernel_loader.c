/**
 * kernel_loader.c
 */

#include "include/kernel/vga_print.c"
#include "src/bootloader/paging.c"

typedef struct __attribute__((packed)) {
    unsigned short bytes_per_sector;
    unsigned char  sectors_per_cluster;
    unsigned short reserved_sectors;
    unsigned char  number_of_fats;
    unsigned int   sectors_per_fat_32;
    unsigned int   root_cluster;
    unsigned char  drive_number;
} bpb_info;

static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outb(unsigned short port, unsigned char val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

static inline unsigned short inw(unsigned short port) {
    unsigned short ret;
    asm volatile ("inw %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outw(unsigned short port, unsigned short val) {
    asm volatile ("outw %0, %1" : : "a"(val), "Nd"(port));
}

void vga_print(volatile const char* string, int line, int character);
int disk_identify(unsigned short *buffer);
void disk_read(unsigned int lba, unsigned char sector_count, unsigned short* buffer);

__attribute__((section(".text.load_kernel")))
unsigned int load_kernel(unsigned int cluster, bpb_info* bpb, unsigned int* kernel_size)
{
    unsigned int buffer_size = (bpb->bytes_per_sector / 2) * bpb->sectors_per_cluster;
    unsigned short buffer[buffer_size];
    *kernel_size = 0;

    // checking the disk exists
    int success = disk_identify(buffer);
    if (!success) 
    {
        const char* disk_find_error = "ERROR: Failed to find disk.";
        vga_print(disk_find_error, 0, 0);
    }

    unsigned int lba; 
    unsigned short* kernel_ptr = (unsigned short*)0x100000;
    while (cluster < 0x0FFFFFF8) 
    {
        // reading the kernel at the fat cluster
        lba = bpb->reserved_sectors + bpb->number_of_fats * bpb->sectors_per_fat_32 + (cluster - 2) * bpb->sectors_per_cluster;
        disk_read(lba, bpb->sectors_per_cluster, buffer);

        // writing 256 words (512 bytes) into memory
        for (int i = 0; i < 256; i++) {
            *kernel_ptr++ = buffer[i];
        }

        unsigned int fat_offset = cluster * 4;
        unsigned int fat_sector = bpb->reserved_sectors + (fat_offset / bpb->bytes_per_sector);
        unsigned int fat_entry_offset = fat_offset % bpb->bytes_per_sector;
        disk_read(fat_sector, 1, buffer);
        *kernel_size += (bpb->bytes_per_sector * bpb->sectors_per_cluster);

        cluster = *(unsigned int*)((char*)buffer + fat_entry_offset) & 0x0FFFFFFF;
    }
    
    return (unsigned int)&paging_init;  // returns pointer to paging function
}

int disk_identify(unsigned short *buffer)
{
    unsigned char status;

    // clear other ports + set master
    outb(0x1F2, 0);
    outb(0x1F3, 0);
    outb(0x1F4, 0);
    outb(0x1F5, 0);
    outb(0x1F6, 0xA0); 

    // identify command
    outb(0x1F7, 0xEC);

    // poll the status port until drive is not busy
    do {
        status = inb(0x1F7);
        if (status == 0) return 0; 
    } while (!(status & 0x08));

    // reading 256 words (512 bytes) 
    for (int i = 0; i < 256; i++) {
        buffer[i] = inw(0x1F0);
    }

    return 1;
}

void disk_read(unsigned int lba, unsigned char sector_count, unsigned short* buffer)
{
    unsigned char status;

    // poll the status port until drive is not busy
    do {
        status = inb(0x1F7);
    } while (status & 0x80);

    outb(0x1F2, sector_count);                          // sector count
    outb(0x1F3, (unsigned char)(lba & 0xFF));           // LBA low
    outb(0x1F4, (unsigned char)((lba >> 8) & 0xFF));    // LBA mid
    outb(0x1F5, (unsigned char)((lba >> 16) & 0xFF));   // LBA high
    outb(0x1F6, 0xE0 | ((lba >> 24) & 0x0F));           // master + LBA bits 24–27

    // read sectors command
    outb(0x1F7, 0x20);

    // poll for read request 
    do {
        status = inb(0x1F7);
    } while (!(status & 0x08));

    // reading 256 words (512 bytes) * sector_count
    for (int i = 0; i < sector_count*256; i++) {
        buffer[i] = inw(0x1F0);
    }

    // poll until read is complete
    do {
        status = inb(0x1F7);
    } while (status & 0x80);
}