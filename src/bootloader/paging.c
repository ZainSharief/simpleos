/*
* paging.c
*/

typedef struct __attribute__((aligned(4096))){
    unsigned int entries[1024];
} page_table;

typedef struct __attribute__((aligned(4096))){
    page_table* tables[1024];
} page_directory;

unsigned int paging_init(unsigned int kernel_phys_base, unsigned int kernel_virt_base, unsigned int kernel_size);
void map_page(page_directory* pd, unsigned int virt_addr, unsigned int phys_addr, unsigned int flags, unsigned int page_table_address);
page_directory* create_page_directory(unsigned int physical_address);
page_table* create_page_table(unsigned int physical_address);

unsigned int paging_init(unsigned int kernel_phys_base, unsigned int kernel_virt_base, unsigned int kernel_size)
{
    unsigned int kernel_end = kernel_phys_base + kernel_size;
    unsigned int kernel_page_boundary = (kernel_end + 0x0FFF) & ~0x0FFF; // aligns to next page boundary ie. 0x1234 -> 0x2000

    page_directory* page_directory = create_page_directory(kernel_page_boundary);

    // identity map the first mb contains useful info such as VGA buffer and this code (quite important)
    page_table* first_page_table = (page_table*)(kernel_page_boundary+0x1000);
    for (int i = 0; i < 256; i++)
        first_page_table->entries[i] = (unsigned int)((i * 0x1000) | 0x03); 
    page_directory->tables[0] = (page_table*)((unsigned int)first_page_table | 0x03);

    // page map 4mb for the kernel
    for (unsigned int i = 0; i < 1024; i++)
        map_page(page_directory, kernel_virt_base + i * 0x1000, kernel_phys_base + i * 0x1000, 0x3, kernel_page_boundary+0x2000); 
        
    return (unsigned int)page_directory;
}

void map_page(page_directory* pd, unsigned int virtual_address, unsigned int physical_address, unsigned int flags, unsigned int page_table_address)
{
    // 31-22 = Page Directory index | 21-12 = Page Table index
    unsigned int pd_index = virtual_address >> 22; // 768
    unsigned int pt_index = (virtual_address >> 12) & 0x3FF; // 0

    page_table* pt = (page_table*)((unsigned int)(pd->tables[pd_index]) & 0xFFFFF000);
    if (!pt) {
        pt = create_page_table(page_table_address);
        pd->tables[pd_index] = (page_table*)(((unsigned int)pt & 0xFFFFF000) | flags);
    }

    pt->entries[pt_index] = (physical_address & 0xFFFFF000) | flags;
}

page_directory* create_page_directory(unsigned int physical_address)
{
    // creates and 0s out the page directory
    page_directory* pd = (page_directory*)physical_address;
    for (int i = 0; i < 1024; i++) 
        pd->tables[i] = 0;  

    return pd;
}

page_table* create_page_table(unsigned int physical_address)
{
    // creates and 0s out the page table
    page_table* pt = (page_table*)physical_address;
    for (int i = 0; i < 1024; i++) 
        pt->entries[i] = 0;  

    return pt;
}