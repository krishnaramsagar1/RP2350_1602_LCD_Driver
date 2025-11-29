<img src="https://github.com/mytechnotalent/RP2350_1602_LCD_Driver/blob/main/RP2350_1602_LCD_Driver.png?raw=true">

## FREE Reverse Engineering Self-Study Course [HERE](https://github.com/mytechnotalent/Reverse-Engineering-Tutorial)
### VIDEO PROMO [HERE](https://www.youtube.com/watch?v=aD7X9sXirF8)

<br>

# RP2350 1602 LCD Driver
An RP2350 1602 LCD driver written entirely in Assembler.

<br>

# Install ARM Toolchain
## NOTE: Be SURE to select `Add path to environment variable` on setup.
[HERE](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)

<br>

# Hardware
## Raspberry Pi Pico 2 w/ Header [BUY](https://www.pishop.us/product/raspberry-pi-pico-2-with-header)
## USB A-Male to USB Micro-B Cable [BUY](https://www.pishop.us/product/usb-a-male-to-usb-micro-b-cable-6-inches)
## Raspberry Pi Pico Debug Probe [BUY](https://www.pishop.us/product/raspberry-pi-debug-probe)
## Complete Component Kit for Raspberry Pi [BUY](https://www.pishop.us/product/complete-component-kit-for-raspberry-pi)
## 10pc 25v 1000uF Capacitor [BUY](https://www.amazon.com/Cionyce-Capacitor-Electrolytic-CapacitorsMicrowave/dp/B0B63CCQ2N?th=1)
### 10% PiShop DISCOUNT CODE - KVPE_HS320548_10PC

<br>

# Build
```
.\build.bat
```

<br>

# Clean
```
.\clean.bat
```

<br>

# main.s Code
```
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
```

<br>

# License
[Apache License 2.0](https://github.com/mytechnotalent/RP2350_UART_Driver/blob/main/LICENSE)
