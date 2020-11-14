%include "const.inc"

[bits 16]
align 16

entry:
	mov	ax, BOOT_SEG   ;0x7c00
	mov	ds,ax
	mov	ax, INIT_SEG   ;0x9000
	mov	es,ax
	mov si, 0
	mov di, 0
	mov cx, 256
	rep movsw

    call clean_screen
	jmp INIT_SEG:go

go:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    ;设置栈段0x9FF00
    mov sp, 0xFF00
	call load_loader_file

    ;获取磁盘驱动参数
	mov	dl, 0x00    ;DL＝驱动器，00H~7FH：软盘；80H~0FFH：硬盘出口参数：CF＝1——操作失败，AH＝状态代码，参见功能号01H中的说明
	                ;否则， BL＝01H — 360K ＝02H — 1.2M ＝03H — 720K ＝04H — 1.44M 
	mov	ax, 0x0800	; AH=8 读取驱动器参数  is get drive parameters
	int	0x13
	mov	ch, 0x00    
	;seg cs
	;mov	sectors,cx
    mov [cs:sectors],ax
	mov	ax, INIT_SEG   ;INIT_SEG = 0x9000
	mov	es,ax

    ;获取光标位置
	mov	ah,0x03		; read cursor pos
	xor	bh,bh
	int	0x10
    ;显示字符"Loading system ..."
	mov	cx,24
	mov	bx,0x0007		; page 0, attribute 7 (normal)
	mov	bp,msg1
	mov	ax,0x1301		; write string, move cursor
	int	0x10

	call load_system_file

;跳转到0x9020:0处执行Loader文件
	jmp LOADER_SEG:0

;将loader映射文件加载到0x9020:0处
load_loader_file:
	mov ax, LOADER_SEG
    mov dx, 0
    mov si, LOADER_OFF
    mov cx, LOADER_CNTS
    xor bx, bx
    call read_sectors
	ret

;将system映射文件加载到0x1000:0处
load_system_file:
	mov ax, SYS_SEG
    mov dx, 0
	mov si, SYS_OFF
	mov cx, SYS_CNTS
    xor bx, bx 
	call read_sectors
	ret

clean_screen:
	mov ax, 0x02
	int 0x10
    ret 

%ifdef CONFIG_BOOT_FLOPPY
; function: read a sector data from floppy
; @input:
;       es: dx -> buffer seg: off
;       si     -> lba
floppy_read_sector:
	push ax 
	push cx 
	push dx 
	push bx 
	
	mov ax, si 
	xor dx, dx 
	mov bx, 18
	
	div bx 
	inc dx 
	mov cl, dl 
	xor dx, dx 
	mov bx, 2
	
	div bx 
	
	mov dh, dl
	xor dl, dl 
	mov ch, al 
	pop bx 
.1:
	mov al, 0x01
	mov ah, 0x02 
	int 0x13 
	jc .1 
	pop dx
	pop cx 
	pop ax
	ret
%endif

%ifdef CONFIG_BOOT_HARDDISK
align 4
DAP:    ; disk address packet
    db 0x10 ; [0]: packet size in bytes
    db 0    ; [1]: reserved, must be 0
    db 0    ; [2]: nr of blocks to transfer (0~127)
    db 0    ; [3]: reserved, must be 0
    dw 0    ; [4]: buf addr(offset)
    dw 0    ; [6]: buf addr(seg)
    dd 0    ; [8]: lba. low 32-bit
    dd 0    ; [12]: lba. high 32-bit

; function: read a sector data from harddisk
; @input:
;       ax: dx  -> buffer seg: off
;       si     -> lba low 32 bits
harddisk_read_sector:
    push ax
    push bx
    push cx
    push dx
    push si

    mov word [DAP + 2], 1       ; count
    mov word [DAP + 4], dx      ; offset
    mov word [DAP + 6], ax      ; segment
    mov word [DAP + 8], si      ; lba low 32 bits
    mov dword [DAP + 12], 0     ; lba high 32 bits
    
    xor bx, bx
    mov ah, 0x42
    mov dl, 0x80
    mov si, DAP
    int 0x13
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
%endif

read_sectors:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

.reply:
    %ifdef CONFIG_BOOT_HARDDISK
    call harddisk_read_sector
    add ax, 0x20    ; next buffer
    %endif
    
    %ifdef CONFIG_BOOT_FLOPPY
    mov es, ax
    call floppy_read_sector
    add bx, 512     ; next buffer
    %endif

    inc si          ; next lba
    loop .reply

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

sectors:
	dw 0

msg1:
	db 13,10
	db "Loading system ..."
	db 13,10,13,10

times 510-($-$$) db 0
dw 0xaa55   ; boot sector flags