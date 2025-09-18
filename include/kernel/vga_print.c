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