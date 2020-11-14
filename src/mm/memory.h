#ifndef __MEM_H__
#define __MEM_H__

#define LOW_MEM 0x100000
#define PAGING_MEMORY (15*1024*1024)     //F00000
#define PAGING_PAGES (PAGING_MEMORY>>12) //F00
#define MAP_NR(addr) (((addr)-LOW_MEM)>>12)
#define USED 100

#define EXT_MEM_K (*(unsigned short *)0x90002)  //loader.S扩展内存容量大小

void mem_init(long start_mem, long end_mem);

#endif