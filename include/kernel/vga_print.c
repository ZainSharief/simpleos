#ifndef VGA_PRINT 
#define VGA_PRINT

void vga_print(volatile const char* string, int line, int character)
{
    // 80x25 vga buffer
	volatile char* vga_buffer = (volatile char*)0xB8000 + line*80*2 + character*2;
	while (*string) 
    {
		*vga_buffer++ = *string++;
		*vga_buffer++ = 0x07;
	}
}

void vga_print_hex(unsigned int hex, int line, int character)
{
    char buf[11]; 
    const char* digits = "0123456789ABCDEF";

    buf[0] = '0';
    buf[1] = 'x';
    buf[2] = digits[(hex >> 28) & 0xF];
    buf[3] = digits[(hex >> 24) & 0xF];
    buf[4] = digits[(hex >> 20) & 0xF];
    buf[5] = digits[(hex >> 16) & 0xF];
    buf[6] = digits[(hex >> 12) & 0xF];
    buf[7] = digits[(hex >> 8)  & 0xF];
    buf[8] = digits[(hex >> 4)  & 0xF];
    buf[9] = digits[(hex >> 0)  & 0xF];
    buf[10] = '\0'; 

    vga_print(buf, line, character);
}

#endif