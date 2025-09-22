OUTPUT_FORMAT("binary")
ENTRY(kernel_main)
SECTIONS
{
	. = 0xC0000000;
	.text :
	{
		KEEP(*(.text.kernel_main))
		*(.text)
	}
	.data :
	{
		*(.data)
	}
	.bss :
	{
		*(.bss)
		*(COMMON)
	}
}