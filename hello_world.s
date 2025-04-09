// Пример ассемблерной вставки Plan9
#include "textflag.h"

TEXT ·hello_world(SB),NOSPLIT,$0
    MOVQ    $1, AX
    MOVQ    $1, DI
    LEAQ    text<>(SB), SI
    MOVQ    $14, DX
    SYSCALL
    RET

DATA text<>+0(SB)/14, $"Hello, world!\n"
GLOBL text<>(SB), RODATA, $14
