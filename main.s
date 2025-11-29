/**
 * FILE: main.s
 *
 * DESCRIPTION:
 * RP2350 Bare-Metal 1602 LCD Main Application.
 * 
 * BRIEF:
 * Main application entry point for RP2350 1602 LCD driver. 
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 2, 2025
 * UPDATE DATE: November 27, 2025
 */

.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

/**
 * Initialize the .text section. 
 * The .text section contains executable code.
 */
.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

/**
 * @brief   Main application entry point.
 *
 * @details Initializes I2C and LCD, displays "Reverse" on line 0 and
 *          "Engineering" on line 1, then enters infinite loop.
 *
 * @param   None
 * @retval  None
 */
.global main                                     // export main
.type main, %function                            // mark as function
main:
.Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.Initialize_I2C:
  bl    I2C1_Init                                // initialize software I2C
  ldr   r0, =500                                 // 500ms delay
  bl    Delay_MS                                 // wait
.Initialize_LCD:
  bl    LCD_Init                                 // initialize LCD display
.Turn_On_Backlight:
  bl    LCD_Backlight_On                         // turn on LCD backlight
.Display_Line_0:
  ldr   r0, =0                                   // line 0
  ldr   r1, =0                                   // position 0
  bl    LCD_Set_Cursor                           // set cursor position
  ldr   r0, =msg_reverse                         // load "Reverse" string
  bl    LCD_Puts                                 // write string to LCD
.Display_Line_1:
  ldr   r0, =1                                   // line 1
  ldr   r1, =0                                   // position 0
  bl    LCD_Set_Cursor                           // set cursor position
  ldr   r0, =msg_engineering                     // load "Engineering" string
  bl    LCD_Puts                                 // write string to LCD
.Wait_10_Seconds:
  ldr   r0, =10000                               // 10 seconds delay
  bl    Delay_MS                                 // wait
.Turn_Off_Backlight:
  bl    LCD_Backlight_Off                        // turn off LCD backlight
.Loop:
  b     .Loop                                    // loop forever
.Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return to caller

/**
 * Test data and constants.
 * The .rodata section is used for constants and static data.
 */
.section .rodata                                 // read-only data section

/**
 * LCD display messages.
 */
msg_reverse:
  .asciz "Reverse"                               // null-terminated string
.align 2                                         // align to 4-byte boundary
msg_engineering:
  .asciz "Engineering"                           // null-terminated string
.align 2                                         // align to 4-byte boundary

/**
 * Initialized global data.
 * The .data section is used for initialized global or static variables.
 */
.section .data                                   // data section

/**
 * Uninitialized global data.
 * The .bss section is used for uninitialized global or static variables.
 */
.section .bss                                    // BSS section
