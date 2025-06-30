
.include "libpi.inc"
.include "constants.inc"

/*
 * O led verde do RPi 2 é o GPIO 47
 */
.set LED, 47

.section .init
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

.text
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
  movs pc, lr
iabort:
  movs pc, lr
dabort:
  movs pc, lr
swi:
  movs pc, lr
irq:
  ldr r0, =PENDING_IRQ_REGISTER
  /* Se não for uma interrupção do grupo 2, para o tratamento */  
  ldr r1, [r0]      @ Acessando o registrador PENDING_BASIC
  tst r1, #1<<9     @ Verificando se o bit 9 está setado
  beq end_irq       @ Se não está setado, acaba o tratamento

  /* Se não for uma interrupção de GPIO, para o tratamento */
  ldr r1, [r0, #8]  @ Acessando o registrador PENDING_2
  tst r1, #1<<20    @ Verifica se o bit 20 está setado
  beq end_irq        @ Se Não está setado, acaba o tramento

  ldr r2, =GPEDS_ADDR
  /*  Verifica se foi detectada borta de descida */
  ldr r1, [r2]        @ Acessando o registrador de detecção de eventos
  tst r1, #1<<12      @ Verifica se o bit 12 está setado
  beq end_irq         @ Se não está setado, acaba o tratamento
  
  /* Aqui temos certeza que a interrupção foi causada por falling edge na GPIO 12 */
  @ Dando toggle na LED
  ldr r0, =RPI_LED_GPIO
  bl gpio_toggle

  /* Reconhece o tratamento de interrupção */
  str r1, [r2]
end_irq:
  movs pc, lr
