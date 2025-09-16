OUTPUT_FORMAT("binary")
ENTRY(load_kernel)
SECTIONS
{
	. = 0x8400;
	.text :
	{
		KEEP(*(.text.load_kernel))
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