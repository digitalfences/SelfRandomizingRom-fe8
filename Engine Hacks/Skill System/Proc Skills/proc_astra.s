.thumb
.macro blh to, reg=r3
  ldr \reg, =\to
  mov lr, \reg
  .short 0xf800
.endm
.equ AstraID, SkillTester+4
.equ d100Result, 0x802a52c
.equ recurse_round, 0x802b83c
@ r0 is attacker, r1 is defender, r2 is current buffer, r3 is battle data
push {r4-r7,lr}
mov r4, r0 @attacker
mov r5, r1 @defender
mov r6, r2 @battle buffer
mov r7, r3 @battle data

@check if we're already in astra
ldrb r0, [r2, #4] @active skill
ldrb r1, AstraID
cmp r0, r1
beq AlreadyAstra
@make sure no other skill is active
cmp r0, #0
bne End

ldr     r0,[r2]           @r0 = battle buffer                @ 0802B40A 6800     
lsl     r0,r0,#0xD                @ 0802B40C 0340     
lsr     r0,r0,#0xD        @Without damage data                @ 0802B40E 0B40     
mov r1, #0xC0 @skill flag
lsl r1, #8 @0xC000
add r1, #0x2 @miss @@@@OR BRAVE??????
tst r0, r1
bne End
@if another skill already activated, don't do anything

@check for Astra proc
ldr r0, SkillTester
mov lr, r0
mov r0, r4 @attacker data
ldr r1, AstraID
.short 0xf800
cmp r0, #0
beq End
@if user has Astra, check for proc rate

ldrb r0, [r4, #0x15] @speed stat as activation rate
mov r1, r4 @skill user
blh d100Result
cmp r0, #1
bne End


@astra effect starts here

@write the damage, since we're skipping ahead
ldrh    r3, [r7, #4]
lsr     r3, #1 @damage halved
strh    r3, [r7, #4]

@ lsl     r3, #0x18

@if we proc
ldr     r2,[r6]    
lsl     r1,r2,#0xD                @ 0802B42C 0351     
lsr     r1,r1,#0xD                @ 0802B42E 0B49     
mov     r0, #0x40
lsl     r0, #8           @0x4000, attacker skill activated
orr     r1, r0
ldr     r0,=#0xFFF80000                @ 0802B434 4804     
and     r0,r2                @ 0802B436 4010     
orr     r0,r1                @ 0802B438 4308   
@ orr     r0,r3  
str     r0,[r6]                @ 0802B43A 6018 
ldrb    r0, AstraID
strb    r0,[r6,#4] @save the thing

@now add the number of rounds - 
mov r1, #0x38
mov r2, sp
ldr r0, [r2,r1] @location of number of rounds on the stack... hopefully
add r0, #4
str r0, [r2,r1]

@HERE'S THE TRICKY BIT: UPDATE A NEW ROUND OF BATTLE AND SET THE OFFENSIVE SKILL FLAG
mov r4, r6

add r4, #8 @next round
mov r0, #0
str     r0,[r4]                @ 0802B43A 6018 
ldrb    r0, AstraID
strb    r0,[r4,#4] @save the thing
mov     r0, #4 @number of extra attacks
strb    r0,[r4,#5]
b End

@ ldr     r0,=0x802b444    @pointer to the current round
@ ldr     r0, [r0]          @current round pointer (usually 203a608)
@ str     r6, [r0]         @update the current round! 

@ mov r0, r4
@ mov r1, r5
@ @ blh recurse_round @call the entire loop again
@ @ add r6, #0x18 @jump ahead
@ ldr     r0,=0x802b444    @pointer to the current round
@ ldr     r0, [r0]          @current round pointer (usually 203a608)
@ ldr     r1, [r0] @current round
@ ldrb    r2, [r1, #5] @number of things?
@ @ str     r6, [r0]         @update the current round! 
@ b End

.ltorg

AlreadyAstra:
@write the damage, since we're skipping ahead
ldrh    r3, [r7, #4]
lsr     r3, #1 @damage halved
strh    r3, [r7, #4]
@ lsl     r3, #0x18
@ ldr     r2, [r6]
@ lsl     r2, #8
@ lsr     r2, #8
@ orr     r2, r3
@ str     r2,[r6]

ldrb    r0,[r6,#5] @attacks remaining
sub     r0, #1
cmp r0, #0
beq End

add     r6, #8
strb    r0,[r6,#5]

@ ldr     r2,[r6]    
@ lsl     r1,r2,#0xD                @ 0802B42C 0351     
@ lsr     r1,r1,#0xD                @ 0802B42E 0B49     
@ mov     r0, #0x40
@ lsl     r0, #8           @0x4000, attacker skill activated
@ orr     r1, r0
@ ldr     r0,=#0xFFF80000                @ 0802B434 4804     
@ and     r0,r2                @ 0802B436 4010     
@ orr     r0,r1                @ 0802B438 4308  
mov r0, #0   
str     r0,[r6]                @ 0802B43A 6018 
ldrb    r0, AstraID
strb    r0,[r6,#4] @save the thing

@ ldr     r0,=0x802b444    @pointer to the current round
@ ldr     r0, [r0]          @current round pointer (usually 203a608)
@ str     r6, [r0]         @update the current round! 

@ mov r0, r4
@ mov r1, r5
@ blh recurse_round @call the entire loop again
@ sub r6, #0x8
@ ldr     r0,=0x802b444    @pointer to the current round
@ ldr     r0, [r0]          @current round pointer (usually 203a608)
@ str     r6, [r0]         @update the current round! 
End:
pop {r4-r7}
pop {r15}

.align
.ltorg
SkillTester:
@POIN SkillTester
@WORD AstraID