## Description
This project is a work-in-progress of following along with the [Performance-Aware Programming Series](https://www.computerenhance.com/p/table-of-contents) by [Casey Muratori](https://github.com/cmuratori).

## Usage

```
> ./sim8086 -help                                           
----- Here is the list of valid arguments: -----
    -show_address: Show address in disassembly
    -a:            Show address in disassembly
    -show_bytes:   Show bytes in disassembly
    -b:            Show bytes in disassembly
    -output_path:  Output path for disassembly
    -o:            Output path for disassembly

    -help, -HELP, -?: Show the list of commands.
```

```
> ./sim8086 ../test/listing_0038_many_register_mov    
; ../test/listing_0038_many_register_mov

bits 16

mov cx, bx
mov ch, ah
mov dx, bx
mov si, bx
mov bx, di
mov al, cl
mov ch, ch
mov bx, ax
mov bx, si
mov sp, di
mov bp, ax
```

```
> ./sim8086 -a -b ../test/listing_0038_many_register_mov
; ../test/listing_0038_many_register_mov

0x0000 | 89 d9 -- -- -- -- | mov cx, bx
0x0002 | 88 e5 -- -- -- -- | mov ch, ah
0x0004 | 89 da -- -- -- -- | mov dx, bx
0x0006 | 89 de -- -- -- -- | mov si, bx
0x0008 | 89 fb -- -- -- -- | mov bx, di
0x000a | 88 c8 -- -- -- -- | mov al, cl
0x000c | 88 ed -- -- -- -- | mov ch, ch
0x000e | 89 c3 -- -- -- -- | mov bx, ax
0x0010 | 89 f3 -- -- -- -- | mov bx, si
0x0012 | 89 fc -- -- -- -- | mov sp, di
0x0014 | 89 c5 -- -- -- -- | mov bp, ax
```

## Build
```
> jai build.jai
```

## Test

```
> jai test.jai
```