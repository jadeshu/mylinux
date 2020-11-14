extern main
extern put_str

global idt_addr,gdt_addr
global ignore_int  ;void ignore_int();
pg_dir: ;页目录 0x0
startup_32:
	jmp startup
	times 0x1000-($-$$) db 0

pg0:   ;页目录表项1
	times 0x1000 db 0
pg1:	;页目录表项2
	times 0x1000 db 0
pg2:	;页目录表项3
	times 0x1000 db 0
pg3:	;页目录表项4
	times 0x1000 db 0

align 2
idt_descr:	;0x5000
	dw 256*8-1		;idt contains 256 entries
	dd idt_addr

align 2
dw 0		;0x5008
gdt_descr:
	dw 256*8-1		; so does gdt (not that that's any
	dd gdt_addr		; magic number, but it works for me :^)

dw 0	
align 8 
gdt_addr:	;0x5010
    dq 0x0000000000000000	;/* NULL descriptor */
	dq 0x00c09a0000000fff	;/* 16Mb */
	dq 0x00c0920000000fff	;/* 16Mb */
	dq 0x00C0920b80000007	; b800 gs写文字区
	dq 0x0000000000000000	;/* TEMPORARY - don't use */
	times 251*8 db 0

idt_addr:		;0x5810
	times 256*8 db 0		; idt is uninitialized

startup:	
	mov esp, 0x9ff00

	call setup_gdt	; 设置全局描述符表
	call setup_idt	; 设置中断描述符表
	
	call setup_paging ;分页
	call main
L6:
	jmp L6	

setup_idt:		
	mov edx, 	ignore_int
	mov eax, 	0x00080000
	mov ax,  	dx		;/* selector = 0x0008 = cs */
	mov dx , 	0x8E00	;/* interrupt gate - dpl=0, present */

	mov edi, 	idt_addr
	mov ecx,	256
rp_sidt:
	mov [edi], eax
	mov [edi+4], edx
	add edi, 8
	dec ecx
	jne rp_sidt
	lidt [idt_descr]
	ret

setup_gdt:
	lgdt [gdt_descr]
	ret

	;共计4页,页目录0~0Xfff
	;第一页0x1000~0x1fff
	;第二页0x2000~0x2fff
	;第三页0x3000~0x3fff
	;第四页0x4000~0x4fff
setup_paging:
	mov ecx, 1024*5   ;循环次数
   	mov esi, 0
.clear_page_dir:
   	mov dword [esi], 0   ;/* pg_dir is at 0x000 */
   	add esi, 4
   	loop .clear_page_dir

	mov eax, pg0+7     ;/* set present bit/user r/w */
	mov [pg_dir], eax
	mov eax, pg1+7
	mov [pg_dir+4], eax
	mov eax, pg2+7
	mov [pg_dir+8], eax
	mov eax, pg3+7
	mov [pg_dir+12], eax
	mov edi, pg3+4092
	mov eax, 0xfff007  ; /*  16Mb - 4096 + 7 (r/w user,p) */
	std	
AGAIN:  
	mov [edi], eax
	sub eax, 0x1000
	sub edi, 4
	cmp edi, 0x1000
	jnz AGAIN

	mov [edi], eax
	;mov eax, 0x1000
	xor eax, eax  ; /* pg_dir is at 0x0000 */
	mov cr3, eax  ;/* cr3 - page directory start */
	mov eax, cr0
	or eax, 0x80000000  ;/* set paging (PG) bit */
	mov cr0, eax
	ret	

ignore_int:	
	push eax
	push ecx
	push edx
	push ds
	push es
	push fs
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	push int_msg
	call put_str
	pop eax
	pop fs
	pop es
	pop ds
	pop edx
	pop ecx
	pop eax
	iret

int_msg:
	db "Unknown interrupt"
	db 13				;换行符
	db 0