
.include "libpi.inc"

/*
 * O led verde do RPi 2 é o GPIO 47
 */
.set LED, 47

.section .init
.text
start:
  ldr pc, _reset
  ldr pc, _undef
  ldr pc, _swi
  ldr pc, _iabort
  ldr pc, _dabort
  nop
  ldr pc, _irq
  ldr pc, _fiq

  _reset:    .word   reset
  _undef:    .word   undef
  _swi:      .word   swi
  _iabort:   .word   iabort
  _dabort:   .word   dabort
  _irq:      .word   irq
  _fiq:      .word   irq


reset:
  /*
   * RITUAL OBRIGATÓRIO -- FAVOR NÃO TENTAR ENTENDER
   * Verifica priviégio de execução EL2 (HYP) ou EL1 (SVC)
   */
  mrs r0, cpsr
  and r0, r0, #0x1f
  cmp r0, #0x1a
  bne continua

  /*
   * Sai do modo EL2 (HYP)
   */
  mrs r0, cpsr
  bic r0, r0, #0x1f
  orr r0, r0, #0x13
  msr spsr_cxsf, r0
  add lr, pc, #4       // aponta o rótulo 'continua'
  msr ELR_hyp, lr
  eret                 // 'retorna' do privilégio EL2 para o EL1

continua:
  /*
   * Verifica o índice das CPUs
   */
  bl get_core
  cmp r0, #0
  beq core0

// Núcleos #1, #2 e #3 vão executar a partir daqui

trava:
  wfe
  b trava

// Execução do núcleo #0
core0:
  /*
   * INICIALIZAÇÃO
   * configura os stack pointers
   */
  mov r0, #0x13     // Modo SVC
  msr cpsr_c,r0
  ldr sp, =stack_addr

  /* Movendo vetor de interrupção para posição 0 da memória */
  ldr r0, =load_addr
  mov r1, #0x0000
  ldmia r0!, {r2,r3,r4,r5,r6,r7,r8,r9}
  stmia r1!, {r2,r3,r4,r5,r6,r7,r8,r9}
  ldmia r0!, {r2,r3,r4,r5,r6,r7,r8,r9}
  stmia r1!, {r2,r3,r4,r5,r6,r7,r8,r9}

 /*
  * Aqui finalmente começa o programa
  */
  b main

undef:
iabort:
dabort:
swi:
irq:
   b .


.set GPREN_ADDR, 0x3F20004C
.set IRQ_ENABLE_2, 0x3F00B214

main:
   /* Habilitando o GPIO 12 para entrada */
   mov r0, #12
   mov r1, #0
   bl gpio_init

  /* Habilita a borda de subida da GPIO 12 */
  ldr r0, =GPREN_ADDR
  mov r1, #1
  lsl r1, #12
  str r1, [r0]

  /* Habilita interrupções IRQ para todas as GPIOs */
  ldr r0, =IRQ_ENABLE_2
  mov r1, #1  
  lsl r1, #20
  str r1, [r0]
  b .

