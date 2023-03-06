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
> ./sim8086 -a -b ../test/listing_0040_challenge_movs
; ../test/listing_0040_challenge_movs

0x0000 | 8b 41 db -- -- -- | mov ax, [bx + di - 37]
0x0003 | 89 8c d4 fe -- -- | mov [si - 300], cx
0x0007 | 8b 57 e0 -- -- -- | mov dx, [bx - 32]
0x000a | c6 03 07 -- -- -- | mov [bp + di], byte 7
0x000d | c7 85 85 03 5b 01 | mov [di + 901], word 347
0x0013 | 8b 2e 05 00 -- -- | mov bp, [5]
0x0017 | 8b 1e 82 0d -- -- | mov bx, [3458]
0x001b | a1 fb 09 -- -- -- | mov ax, [2555]
0x001e | a1 10 00 -- -- -- | mov ax, [16]
0x0021 | a3 fa 09 -- -- -- | mov [2554], ax
0x0024 | a3 0f 00 -- -- -- | mov [15], ax
```

## Build
```
> jai build.jai
```

## Test

```
> jai test.jai
```