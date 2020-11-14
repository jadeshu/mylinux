#include "memory.h"

static long HIGH_MEMORY = 0;
static unsigned char mem_map[ PAGING_PAGES ] = {0,};
// start_mem = 4M
// end_mem = 16M
void mem_init(long start_mem, long end_mem)
{
	int i;

	HIGH_MEMORY = end_mem;
	// PAGING_PAGES = 0xF00(3840)
	for (i=0 ; i<PAGING_PAGES ; i++)
    {
        mem_map[i] = USED;
    }
	//MAP_NR(addr) (((addr)-1M)>>12)
	// i = (4M-1M)>>12 = 0x300
	i = MAP_NR(start_mem);
	//end_mem= 12M
	end_mem -= start_mem; 
	//end_mem= 0xC00
	end_mem >>= 12; 
	while ( end_mem-- > 0)
		// 把mem_map从3M~15M清零
		mem_map[i++] = 0;
}