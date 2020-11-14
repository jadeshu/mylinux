%include "const.inc"

[bits 16]
align 16

entry:
;获取光标位置与形态
	mov	ax, INIT_SEG	; this is done in bootsect already, but...
	mov	ds, ax
	mov	ah, 0x03	; read cursor pos
	xor	bh, bh
	int	0x10		; save it in known place, con_init fetches
	mov	[0], dx		; it from 0x90000.

;Get memory size (extended mem, kB)
;获取扩展内存容量。
	mov	ah, 0x88
	int	0x15
	mov	[2],ax

;获取显示方式
	mov	ah, 0x0f
	int	0x10
	mov	[4],bx		; bh = display page
	mov	[6],ax		; al = video mode, ah = window width

; 控制器RAM诊断
	mov	ah,   0x12
	mov	bl,   0x10
	int	0x10
	mov	[8],  ax
	mov	[10], bx
	mov	[12], cx


; Get hd0 data
;获取第一个硬盘信息
	mov	ax,     0x0000
	mov	ds,     ax
	lds	si,     [4 * 0x41]
	mov	ax,     INIT_SEG
	mov	es,     ax
	mov	di,     0x0080
	mov	cx,     0x10
	rep 
    movsb

; Get hd1 data
;获取第二个硬盘信息
	mov	ax,     0x0000
	mov	ds,     ax
	lds	si,     [4 * 0x46]
	mov	ax,     INIT_SEG
	mov	es,     ax
	mov	di,     0x0090
	mov	cx,     0x10
	rep
	movsb

;Check that there IS a hd1 :-)
	mov	ax,     0x01500
	mov	dl,     0x81
	int	0x13
	jc	no_disk1
	cmp	ah,     3
	je	is_disk1
no_disk1:
	mov	ax,     INIT_SEG
	mov	es,     ax
	mov	di,     0x0090
	mov	cx,     0x10
	mov	ax,     0x00
	rep
	stosb
is_disk1:
;关闭中断
	cli	

;将system从0x1000:0移动到0
    mov	ax,     0
    cld  ;方向为向前
do_move:
    mov es,     ax      ;目的地
    add ax,     0x1000
    cmp ax,     0x9000
    jz end_move
	mov	ds,     ax
	mov si,     0
	mov di,     0
	mov cx,     0x8000
	rep 
    movsw
    jmp do_move

end_move:
	;----------------从现在之后实模式下的int不可调用，内存数据已经被覆盖了------------
    mov ax, LOADER_SEG
	mov ds, ax 

 	;jmp set_protect_mode
 set_protect_mode:
    ;-----------------   准备进入保护模式   -------------------
    ;-----------------1.  打开A20  ----------------
    in al,0x92
    or al,0000_0010B
    out 0x92,al
    ;-----------------2.  加载GDT  ----------------
    lgdt [gdt_48]

	;-----------------重新设置8259A芯片-----------
	mov	al, 0x11		; initialization sequence
	out	0x20,al			; send it to 8259A-1
	
	; nop
	dw	0x00eb,0x00eb		; jmp $+2, jmp $+2
	
	out	0xA0,al		; and to 8259A-2
	
	dw	0x00eb,0x00eb
	
	mov	al, 0x20		; start of hardware int's (0x20)
	out	0x21,al
	
	dw	0x00eb,0x00eb
	
	mov	al, 0x28		; start of hardware int's 2 (0x28)
	out	0xA1,al
	
	dw	0x00eb,0x00eb
	
	mov	al, 0x04		; 8259-1 is master
	out	0x21,al
	
	dw	0x00eb,0x00eb
	
	mov	al, 0x02		; 8259-2 is slave
	out	0xA1,al
	
	dw	0x00eb,0x00eb
	
	mov	al, 0x01		; 8086 mode for both
	out	0x21,al
	
	dw	0x00eb,0x00eb
	
	out	0xA1, al
	
	dw	0x00eb,0x00eb
	
	mov	al, 0xFF		; mask off all interrupts for now
	out	0x21,al
	
	dw	0x00eb,0x00eb
	
	out	0xA1,al

    ;-----------------3.  cr0第0位置1  ----------------
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax


	;----------------- 进入保护模式，强制刷新流水线------------------
	;loader.S被调入内存起始地址为0x90200
    jmp dword 0x08:0x90200+p_mode_start

;临时GDT，为了进入保护模式的
gdt_table:
	dq	0		; dummy

	dw	0x07FF		; 8Mb - limit=2047 (2048*4096=8Mb)
	dw	0x0000		; base address=0
	dw	0x9A00		; code read/exec
	dw	0x00C0		; granularity=4096, 386

	dw	0x07FF		; 8Mb - limit=2047 (2048*4096=8Mb)
	dw	0x0000		; base address=0
	dw	0x9200		; data read/write
	dw	0x00C0		; granularity=4096, 386

gdt_length equ ($ - gdt_table)
gdt_48:
    dw	(gdt_length-1)
	dw	512+gdt_table,0x9 ;gdt base = 0X9xxxx,512字节是MBR

[bits 32]  
align 32
p_mode_start:
    mov ax, 0x10	;the data selector
	mov ds, ax 
	mov es, ax 
	mov fs, ax 
	mov gs, ax 
	mov ss, ax 
	jmp dword 0x08:0