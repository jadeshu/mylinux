#include "print.h"
#include "memory.h"
static long memory_end = 0;	// 最大内存
static long buffer_memory_end = 0; 
static long main_memory_start = 0; //主内存开始位置

int main()
{
    memory_end = (1<<20) + (EXT_MEM_K<<10);  // 1M + 扩展内存
	memory_end &= 0xfffff000;				 // 去掉低12位，不满4K内存
	if (memory_end > 16*1024*1024)		     // memory_end > 16MB
		memory_end = 16*1024*1024;           // memory_end = 16MB
		
	if (memory_end > 12*1024*1024)           // memory_end > 12MB
		buffer_memory_end = 4*1024*1024;     // buffer_memory_end = 4MB
	else if (memory_end > 6*1024*1024)       // memory_end < 12MB memory_end > 6MB  
		buffer_memory_end = 2*1024*1024;     // buffer_memory_end = 2MB
	else
		buffer_memory_end = 1*1024*1024;     // buffer_memory_end = 1MB
		
	main_memory_start = buffer_memory_end;   // main_memory_start从缓存内存结束位置开始
    
    mem_init(main_memory_start,memory_end);  // 内存初始化

    put_str("memory start:");
    put_int(main_memory_start);
    put_str("\n");
    put_str("memory end:");
    put_int(memory_end);
    put_str("\n");

    while(1){
        io_hlt();
    }
    return 0;
}