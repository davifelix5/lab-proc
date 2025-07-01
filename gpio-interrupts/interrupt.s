.include "constants.inc"

.global main

.text
main:
   /* Habilitando o GPIO 12 para entrada */
   ldr r0, =RPI_INPUT_GPIO
   mov r1, #0                @ Entrada
   bl gpio_init

   ldr r0, =RPI_LED_GPIO
   mov r1, #1                @ Saída
   bl gpio_init

  /* Habilita a borda de descida da GPIO 12 - BIT 12 do registrador GPFEN0 */
  ldr r0, =GPFEN_ADDR
  ldr r1, [r0]             @ Lê o valor atual do registrador GPFEN
  orr r1, r1, #1<<12       @ Seta apenas o bit 12 do registrador GPFEN
  str r1, [r0]

  /* Habilita interrupções IRQ para todas as GPIOs: bit 20 do rehistrador IRQ_enable2 */
  ldr r0, =ENABLE_IRQ_REGISTER
  ldr r1, [r0, #4]        @ Lê o valor atual do registrador IRQ_enable2
  orr r1, r1, #1<<20      @ Sera o bit 20 do registrador IRQ_enable2
  str r1, [r0, #4]
  b .
