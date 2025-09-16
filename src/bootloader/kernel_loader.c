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
void disk_write(unsigned int lba, unsigned char sector_count, unsigned short* buffer);
void disk_read(unsigned int lba, unsigned char sector_count, unsigned short* buffer);

__attribute__((section(".text.load_kernel")))
void load_kernel()
{
    unsigned short buffer[256];

    int success = disk_identify(buffer);
    if (!success) 
    {
        const char* disk_find_error = "ERROR: Failed to find disk.";
        vga_print(disk_find_error, 0, 0);
    }

    for(;;){}

    return;
}

void vga_print(volatile const char* string, int line, int character)
{
	volatile char* vga_buffer = (volatile char*)0xB8000 + line*80*2 + character*2;
	while (*string) {
		*vga_buffer++ = *string++;
		*vga_buffer++ = 0x07;
	}
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

void disk_write(unsigned int lba, unsigned char sector_count, unsigned short* buffer)
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

    // write sectors command
    outb(0x1F7, 0x30);

    // poll for write request 
    do {
        status = inb(0x1F7);
    } while (!(status & 0x08));

    // writing 256 words (512 bytes) * sector_count
    for (int i = 0; i < sector_count*256; i++) {
        outw(0x1F0, buffer[i]);
    }

    // poll until write is complete
    do {
        status = inb(0x1F7);
    } while (status & 0x80);
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
    } while (!(status & 0x01));

    // reading 256 words (512 bytes) * sector_count
    for (int i = 0; i < sector_count*256; i++) {
        buffer[i] = inw(0x1F0);
    }

    // poll until read is complete
    do {
        status = inb(0x1F7);
    } while (status & 0x80);
}