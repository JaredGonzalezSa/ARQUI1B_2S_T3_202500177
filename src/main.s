.global _start

.section .data
    // --- Mensajes para la consola ---
    msg_original:  .ascii "\n=== Arreglo Original ===\n"
    len_original = . - msg_original

    msg_bubble:    .ascii "\n=== Arreglo Ordenado (Bubble Sort) ===\n"
    len_bubble = . - msg_bubble

    msg_selection: .ascii "\n=== Arreglo Ordenado (Selection Sort) ===\n"
    len_selection = . - msg_selection

    msg_coma:      .ascii ", "
    len_coma = . - msg_coma

    msg_salto:     .ascii "\n"
    len_salto = . - msg_salto

    // --- Arreglo de 10 elementos (64 bits cada uno) ---
    arreglo: .quad 45, 12, 89, 5, 23, 78, 1, 99, 34, 56
    tamanio = 10     

.section .bss
    buffer_num: .skip 32

.section .text

_start:
    // 1. Imprimir el arreglo original
    mov x0, #1              
    ldr x1, =msg_original   
    mov x2, len_original    
    mov x8, #64             
    svc #0

    ldr x0, =arreglo        
    mov x1, tamanio         
    bl print_array          

    // 2. Ejecutar Bubble Sort
    ldr x0, =arreglo        // Parámetro 1: Dirección base
    mov x1, tamanio         // Parámetro 2: Tamaño
    bl bubble_sort          

    // 3. Imprimir resultado de Bubble Sort
    mov x0, #1              
    ldr x1, =msg_bubble   
    mov x2, len_bubble    
    mov x8, #64             
    svc #0

    ldr x0, =arreglo        
    mov x1, tamanio         
    bl print_array          


    // 4. Ejecutar Selection Sort
    ldr x0, =arreglo        // Parámetro 1: Dirección base
    mov x1, tamanio         // Parámetro 2: Tamaño
    bl selection_sort       

    // 5. Imprimir resultado de Selection Sort
    mov x0, #1              
    ldr x1, =msg_selection   
    mov x2, len_selection    
    mov x8, #64             
    svc #0

    ldr x0, =arreglo        
    mov x1, tamanio         
    bl print_array          

    // 6. Salir del programa limpiamente
    mov x0, #0
    mov x8, #93
    svc #0

// ======================================================================
// SUBRUTINA: bubble_sort
// Propósito: Ordenar in-place comparando elementos adyacentes
// ======================================================================
bubble_sort:
    stp x29, x30, [sp, #-32]!   
    mov x29, sp
    stp x19, x20, [sp, #16]     

    mov x19, x0                 // x19 = Dirección base
    sub x20, x1, #1             // x20 = N - 1
    
    cmp x20, #0                 
    ble bs_end
    
    mov x9, #0                  // i = 0

bs_outer_loop:
    cmp x9, x20                 
    bge bs_end                  

    mov x10, #0                 // j = 0
    sub x11, x20, x9            // Límite interno = (N - 1) - i

bs_inner_loop:
    cmp x10, x11                
    bge bs_outer_next           

    lsl x12, x10, #3            // Multiplicar j * 8 bytes
    add x13, x19, x12           // Dirección de arr[j]
    
    ldr x14, [x13]              // arr[j]
    ldr x15, [x13, #8]          // arr[j+1]

    cmp x14, x15                // Si arr[j] <= arr[j+1], no hacer nada
    ble bs_inner_next           

    str x15, [x13]              // Swap (Intercambio)
    str x14, [x13, #8]          

bs_inner_next:
    add x10, x10, #1            
    b bs_inner_loop             

bs_outer_next:
    add x9, x9, #1              
    b bs_outer_loop             

bs_end:
    ldp x19, x20, [sp, #16]     
    ldp x29, x30, [sp], #32     
    ret                         


// ======================================================================
// SUBRUTINA: selection_sort
// Propósito: Ordenar in-place buscando el elemento más pequeño y 
//            moviéndolo a la posición actual.
// Entradas:  x0 = Dirección base del arreglo | x1 = Tamaño
// ======================================================================
selection_sort:
    // --- MANEJO DEL STACK ---
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov x19, x0                 // x19 = Dirección base
    mov x20, x1                 // x20 = N (Tamaño)
    
    sub x21, x20, #1            // x21 = N - 1 (Límite del ciclo exterior)
    cmp x21, #0
    ble ss_end                  // Si el arreglo tiene 0 o 1 elementos, terminar
    
    mov x9, #0                  // x9 = i (Contador exterior)

ss_outer_loop:
    // for (i = 0; i < N - 1; i++)
    cmp x9, x21                 
    bge ss_end

    mov x10, x9                 // x10 = min_idx (Asumimos que el actual es el menor)
    add x11, x9, #1             // x11 = j (Inicia en i + 1)

ss_inner_loop:
    // for (j = i + 1; j < N; j++)
    cmp x11, x20                
    bge ss_swap                 // Si terminó el ciclo interno, vamos a intercambiar

    // Cargar arr[j]
    lsl x12, x11, #3            // j * 8 bytes
    add x13, x19, x12           // Dirección de arr[j]
    ldr x14, [x13]              // x14 = arr[j]

    // Cargar arr[min_idx]
    lsl x15, x10, #3            // min_idx * 8 bytes
    add x16, x19, x15           // Dirección de arr[min_idx]
    ldr x17, [x16]              // x17 = arr[min_idx]

    // Comparar arr[j] con arr[min_idx]
    cmp x14, x17                
    bge ss_inner_next           // Si arr[j] >= arr[min_idx], ignorar

    mov x10, x11                // Si es menor, actualizar min_idx = j

ss_inner_next:
    add x11, x11, #1            // j++
    b ss_inner_loop             

ss_swap:
    // Intercambiar arr[i] y arr[min_idx] solo si i != min_idx
    cmp x9, x10                 
    beq ss_outer_next           // Si son iguales, saltar el intercambio

    // Cargar arr[i]
    lsl x12, x9, #3             
    add x13, x19, x12           
    ldr x14, [x13]              

    // Cargar arr[min_idx]
    lsl x15, x10, #3            
    add x16, x19, x15           
    ldr x17, [x16]              

    // Hacer el swap (guardar cruzado)
    str x17, [x13]              // Guardar el menor en la posición 'i'
    str x14, [x16]              // Guardar el viejo arr[i] en 'min_idx'

ss_outer_next:
    add x9, x9, #1              // i++
    b ss_outer_loop             

ss_end:
    // --- RESTAURAR EL STACK ---
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret                         


// ======================================================================
// SUBRUTINA: print_array
// ======================================================================
print_array:
    stp x29, x30, [sp, #-48]!   
    mov x29, sp                 
    stp x19, x20, [sp, #16]     
    stp x21, x22, [sp, #32]     

    mov x19, x0                 
    mov x20, x1                 
    mov x21, #0                 

loop_print:
    cmp x21, x20                
    beq end_print               

    ldr x0, [x19]               
    
    ldr x1, =buffer_num         
    add x1, x1, #32             
    bl itoa                     

    mov x0, #1                  
    mov x8, #64                 
    svc #0                      

    add x22, x21, #1            
    cmp x22, x20                
    beq skip_coma               

    mov x0, #1
    ldr x1, =msg_coma
    mov x2, len_coma
    mov x8, #64
    svc #0

skip_coma:
    add x19, x19, #8            
    add x21, x21, #1            
    b loop_print                

end_print:
    mov x0, #1
    ldr x1, =msg_salto
    mov x2, len_salto
    mov x8, #64
    svc #0

    ldp x21, x22, [sp, #32]     
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48     
    ret                         

.include "src/06_itoa.s"