
SECTIONS {
   /* Endereço do Linux na RAM do RPi */
   . = 0x8000;
   .init : {
      load_addr = .;
      *(.init)
   }
   .text : { *(.text) }
   . = ALIGN(4);
   .data : { *(.data) }

   /* Pilha SVR */
   . = . + 8K;
   . = ALIGN(8);
   stack_addr = .;       /* Topo da pilha */
}

