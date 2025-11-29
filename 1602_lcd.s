/**
 * FILE: 1602_lcd.s
 *
 * DESCRIPTION:
 * RP2350 1602 LCD Software I2C Driver (Bit-Bang).
 * 
 * BRIEF:
 * Provides LCD initialization, control, and display functions over software I2C.
 * Supports HD44780-compatible 16x2 LCD displays via PCF8574 I2C expander.
 * Uses bit-banging on GPIO2 (SDA) and GPIO3 (SCL).
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 29, 2025
 * UPDATE DATE: November 29, 2025
 */

.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

/**
 * GPIO and I2C Configuration
 */
.equ SDA_PIN,                2                   // GPIO2 - I2C SDA
.equ SCL_PIN,                3                   // GPIO3 - I2C SCL
.equ SDA_MASK,               (1<<2)              // GPIO2 bit mask
.equ SCL_MASK,               (1<<3)              // GPIO3 bit mask
.equ LCD_I2C_ADDR,           0x27                // PCF8574 I2C address
.equ LCD_BACKLIGHT,          0x08                // backlight bit
.equ LCD_EN,                 0x04                // enable bit
.equ LCD_RS,                 0x01                // register select bit

/**
 * SIO Base for direct GPIO control
 */
.equ SIO_BASE,               0xD0000000          // SIO base address
.equ SIO_GPIO_OUT_SET,       0x014               // GPIO output set
.equ SIO_GPIO_OUT_CLR,       0x018               // GPIO output clear
.equ SIO_GPIO_OE_SET,        0x024               // GPIO output enable set
.equ SIO_GPIO_OE_CLR,        0x028               // GPIO output enable clear
.equ SIO_GPIO_IN,            0x004               // GPIO input

/**
 * Initialize the .text section. 
 * The .text section contains executable code.
 */
.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

/**
 * @brief   I2C delay for timing (~5us for 100kHz).
 *
 * @param   None
 * @retval  None
 */
.type I2C_Delay, %function
I2C_Delay:
  push  {r4, lr}                                 // push registers
  ldr   r4, =72                                  // delay loops for ~5us @ 14.5MHz (increased for reliability)
.I2C_Delay_Loop:
  subs  r4, r4, #1                               // decrement
  bne   .I2C_Delay_Loop                          // loop
  pop   {r4, lr}                                 // pop registers
  bx    lr                                       // return

/**
 * @brief   Set SDA high (release line, pull-up brings it high).
 *
 * @param   None
 * @retval  None
 */
.type SDA_High, %function
SDA_High:
  push  {r4, lr}                                 // push registers
  ldr   r0, =SDA_PIN                             // GPIO2
  ldr   r4, =0                                   // disable OE (input/high-z)
  mcrr  p0, #4, r0, r4, c4                       // gpioc_bit_oe_put(SDA_PIN, 0)
  pop   {r4, lr}                                 // pop registers
  bx    lr                                       // return

/**
 * @brief   Drive SDA low.
 *
 * @param   None
 * @retval  None
 */
.type SDA_Low, %function
SDA_Low:
  push  {r4, lr}                                 // push registers
  ldr   r0, =SDA_PIN                             // GPIO2
  ldr   r4, =0                                   // output 0
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(SDA_PIN, 0)
  ldr   r4, =1                                   // enable OE
  mcrr  p0, #4, r0, r4, c4                       // gpioc_bit_oe_put(SDA_PIN, 1)
  pop   {r4, lr}                                 // pop registers
  bx    lr                                       // return

/**
 * @brief   Set SCL high (release line, pull-up brings it high).
 *
 * @param   None
 * @retval  None
 */
.type SCL_High, %function
SCL_High:
  push  {r4, lr}                                 // push registers
  ldr   r0, =SCL_PIN                             // GPIO3
  ldr   r4, =0                                   // disable OE (input/high-z)
  mcrr  p0, #4, r0, r4, c4                       // gpioc_bit_oe_put(SCL_PIN, 0)
  pop   {r4, lr}                                 // pop registers
  bx    lr                                       // return

/**
 * @brief   Drive SCL low.
 *
 * @param   None
 * @retval  None
 */
.type SCL_Low, %function
SCL_Low:
  push  {r4, lr}                                 // push registers
  ldr   r0, =SCL_PIN                             // GPIO3
  ldr   r4, =0                                   // output 0
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(SCL_PIN, 0)
  ldr   r4, =1                                   // enable OE
  mcrr  p0, #4, r0, r4, c4                       // gpioc_bit_oe_put(SCL_PIN, 1)
  pop   {r4, lr}                                 // pop registers
  bx    lr                                       // return

/**
 * @brief   Initialize software I2C GPIO pins.
 *
 * @param   None
 * @retval  None
 */
.global I2C1_Init
.type I2C1_Init, %function
I2C1_Init:
.I2C1_Init_Push:
  push  {r4-r12, lr}                             // push registers
.I2C1_Init_Enable_Coprocessor:
  bl    Enable_Coprocessor                       // enable coprocessor access
.I2C1_Init_Config_GPIO2:
  ldr   r0, =0x0c                                // GPIO2 pad offset
  ldr   r1, =0x14                                // GPIO2 ctrl offset
  ldr   r2, =SDA_PIN                             // GPIO2 pin number
  bl    GPIO_Config                              // configure GPIO2 (SDA)
.I2C1_Init_Config_GPIO3:
  ldr   r0, =0x10                                // GPIO3 pad offset
  ldr   r1, =0x1c                                // GPIO3 ctrl offset
  ldr   r2, =SCL_PIN                             // GPIO3 pin number
  bl    GPIO_Config                              // configure GPIO3 (SCL)
.I2C1_Init_Set_Idle:
  bl    SDA_High                                 // set SDA high (idle)
  bl    SCL_High                                 // set SCL high (idle)
.I2C1_Init_Pop:
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return



/**
 * @brief   Send I2C start condition.
 *
 * @param   None
 * @retval  None
 */
.global I2C_Start
.type I2C_Start, %function
I2C_Start:
  push  {r4-r12, lr}                             // push registers
  bl    SDA_High                                 // SDA high
  bl    I2C_Delay                                // delay
  bl    SCL_High                                 // SCL high
  bl    I2C_Delay                                // delay
  bl    SDA_Low                                  // SDA low (start condition)
  bl    I2C_Delay                                // delay
  bl    SCL_Low                                  // SCL low
  bl    I2C_Delay                                // delay
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Send I2C stop condition.
 *
 * @param   None
 * @retval  None
 */
.global I2C_Stop
.type I2C_Stop, %function
I2C_Stop:
  push  {r4-r12, lr}                             // push registers
  bl    SDA_Low                                  // SDA low
  bl    I2C_Delay                                // delay
  bl    SCL_High                                 // SCL high
  bl    I2C_Delay                                // delay
  bl    SDA_High                                 // SDA high (stop condition)
  bl    I2C_Delay                                // delay
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Write one bit to I2C bus.
 *
 * @param   r0 - bit value (0 or 1)
 * @retval  None
 */
.type I2C_Write_Bit, %function
I2C_Write_Bit:
  push  {r4-r12, lr}                             // push registers
  cmp   r0, #0                                   // check bit value
  beq   .I2C_Write_Bit_Low                       // branch if 0
  bl    SDA_High                                 // set SDA high
  b     .I2C_Write_Bit_Clock                     // continue
.I2C_Write_Bit_Low:
  bl    SDA_Low                                  // set SDA low
.I2C_Write_Bit_Clock:
  bl    I2C_Delay                                // delay
  bl    SCL_High                                 // SCL high
  bl    I2C_Delay                                // delay
  bl    SCL_Low                                  // SCL low
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Read one bit from I2C bus (for ACK).
 *
 * @param   None
 * @retval  r0 - bit value read
 */
.type I2C_Read_Bit, %function
I2C_Read_Bit:
  push  {r4-r12, lr}                             // push registers
  bl    SDA_High                                 // release SDA
  bl    I2C_Delay                                // delay
  bl    SCL_High                                 // SCL high
  bl    I2C_Delay                                // delay
  ldr   r4, =SIO_BASE                            // load SIO base
  ldr   r5, [r4, #SIO_GPIO_IN]                   // read GPIO inputs
  lsr   r5, r5, #SDA_PIN                         // shift to SDA bit
  and   r0, r5, #1                               // mask bit
  bl    SCL_Low                                  // SCL low
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Write one byte to I2C bus.
 *
 * @param   r0 - byte to write
 * @retval  r0 - ACK bit (0=ACK, 1=NACK)
 */
.global I2C1_Write_Byte
.type I2C1_Write_Byte, %function
I2C1_Write_Byte:
  push  {r4-r12, lr}                             // push registers
  mov   r4, r0                                   // save byte
  ldr   r5, =8                                   // bit counter
.I2C1_Write_Byte_Loop:
  lsr   r0, r4, #7                               // get MSB
  and   r0, r0, #1                               // mask bit
  bl    I2C_Write_Bit                            // write bit
  lsl   r4, r4, #1                               // shift left
  subs  r5, r5, #1                               // decrement counter
  bne   .I2C1_Write_Byte_Loop                    // loop until done
  bl    I2C_Read_Bit                             // read ACK bit
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Write 4-bit nibble to LCD.
 *
 * @param   r0 - nibble in upper 4 bits
 * @param   r1 - RS bit (0=command, 1=data)
 * @retval  None
 */
.type LCD_Write_Nibble, %function
LCD_Write_Nibble:
  push  {r4-r12, lr}                             // push registers
  mov   r4, r0                                   // save nibble
  mov   r5, r1                                   // save RS
  orr   r6, r4, r5                               // combine nibble | RS
  orr   r6, r6, #LCD_BACKLIGHT                   // add backlight bit
  orr   r7, r6, #LCD_EN                          // create EN=1 byte
  bl    I2C_Start                                // I2C start
  ldr   r0, =(LCD_I2C_ADDR<<1)                   // I2C address (write)
  bl    I2C1_Write_Byte                          // write address
  mov   r0, r7                                   // data (EN=1)
  bl    I2C1_Write_Byte                          // write data
  bl    I2C_Stop                                 // I2C stop
  ldr   r0, =1                                   // 1us delay
  bl    Delay_US                                 // delay
  bl    I2C_Start                                // I2C start
  ldr   r0, =(LCD_I2C_ADDR<<1)                   // I2C address (write)
  bl    I2C1_Write_Byte                          // write address
  mov   r0, r6                                   // data (EN=0)
  bl    I2C1_Write_Byte                          // write data
  bl    I2C_Stop                                 // I2C stop
  ldr   r0, =50                                  // 50us delay
  bl    Delay_US                                 // delay
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Write full byte to LCD as two nibbles.
 *
 * @param   r0 - byte to write
 * @param   r1 - RS bit (0=command, 1=data)
 * @retval  None
 */
.type LCD_Write_Byte, %function
LCD_Write_Byte:
  push  {r4-r12, lr}                             // push registers
  mov   r4, r0                                   // save byte
  mov   r5, r1                                   // save RS
  and   r0, r4, #0xF0                            // get upper nibble
  mov   r1, r5                                   // set RS
  bl    LCD_Write_Nibble                         // write upper nibble
  lsl   r0, r4, #4                               // shift lower nibble to upper
  and   r0, r0, #0xF0                            // mask nibble
  mov   r1, r5                                   // set RS
  bl    LCD_Write_Nibble                         // write lower nibble
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Send command to LCD.
 *
 * @param   r0 - command byte
 * @retval  None
 */
.type LCD_Command, %function
LCD_Command:
  push  {r4-r12, lr}                             // push registers
  ldr   r1, =0                                   // RS=0 for command
  bl    LCD_Write_Byte                           // write command
  ldr   r0, =2                                   // 2ms delay
  bl    Delay_MS                                 // delay
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Initialize LCD display.
 *
 * @param   None
 * @retval  None
 */
.global LCD_Init
.type LCD_Init, %function
LCD_Init:
  push  {r4-r12, lr}                             // push registers
  ldr   r0, =50                                  // 50ms delay
  bl    Delay_MS                                 // power-on delay
  ldr   r0, =0x30                                // function set (8-bit)
  ldr   r1, =0                                   // RS=0
  bl    LCD_Write_Nibble                         // write nibble
  ldr   r0, =5                                   // 5ms delay
  bl    Delay_MS                                 // delay
  ldr   r0, =0x30                                // function set (8-bit)
  ldr   r1, =0                                   // RS=0
  bl    LCD_Write_Nibble                         // write nibble
  ldr   r0, =1                                   // 150us delay (1ms for safety)
  bl    Delay_MS                                 // delay
  ldr   r0, =0x30                                // function set (8-bit)
  ldr   r1, =0                                   // RS=0
  bl    LCD_Write_Nibble                         // write nibble
  ldr   r0, =1                                   // 150us delay (1ms for safety)
  bl    Delay_MS                                 // delay
  ldr   r0, =0x20                                // function set (4-bit)
  ldr   r1, =0                                   // RS=0
  bl    LCD_Write_Nibble                         // write nibble
  ldr   r0, =1                                   // 150us delay (1ms for safety)
  bl    Delay_MS                                 // delay
  ldr   r0, =0x28                                // function set: 4-bit, 2 line, 5x8
  bl    LCD_Command                              // send command
  ldr   r0, =0x0C                                // display on, cursor off, blink off
  bl    LCD_Command                              // send command
  ldr   r0, =0x06                                // entry mode: increment, no shift
  bl    LCD_Command                              // send command
  ldr   r0, =0x01                                // clear display
  bl    LCD_Command                              // send command
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Clear LCD display.
 *
 * @param   None
 * @retval  None
 */
.global LCD_Clear
.type LCD_Clear, %function
LCD_Clear:
  push  {r4-r12, lr}                             // push registers
  ldr   r0, =0x01                                // clear display command
  bl    LCD_Command                              // send command
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Set LCD cursor position.
 *
 * @param   r0 - line (0 or 1)
 * @param   r1 - position (0-15)
 * @retval  None
 */
.global LCD_Set_Cursor
.type LCD_Set_Cursor, %function
LCD_Set_Cursor:
  push  {r4-r12, lr}                             // push registers
  cmp   r0, #1                                   // check line
  bgt   .LCD_Set_Cursor_Line1                    // limit to line 1
  cmp   r0, #0                                   // check if line 0
  beq   .LCD_Set_Cursor_Calc                     // use line 0 offset
.LCD_Set_Cursor_Line1:
  ldr   r0, =0x40                                // line 1 offset
  b     .LCD_Set_Cursor_Add
.LCD_Set_Cursor_Calc:
  ldr   r0, =0x00                                // line 0 offset
.LCD_Set_Cursor_Add:
  add   r0, r0, r1                               // add position
  orr   r0, r0, #0x80                            // set DDRAM address command
  bl    LCD_Command                              // send command
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Write string to LCD.
 *
 * @param   r0 - pointer to null-terminated string
 * @retval  None
 */
.global LCD_Puts
.type LCD_Puts, %function
LCD_Puts:
  push  {r4-r12, lr}                             // push registers
  mov   r4, r0                                   // save string pointer
.LCD_Puts_Loop:
  ldrb  r0, [r4]                                 // load byte from string
  cmp   r0, #0                                   // check for null terminator
  beq   .LCD_Puts_Done                           // exit if null
  ldr   r1, =LCD_RS                              // RS=1 for data
  bl    LCD_Write_Byte                           // write character
  add   r4, r4, #1                               // increment pointer
  b     .LCD_Puts_Loop                           // loop
.LCD_Puts_Done:
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Write character to LCD.
 *
 * @param   r0 - character to write
 * @retval  None
 */
.global LCD_Putc
.type LCD_Putc, %function
LCD_Putc:
  push  {r4-r12, lr}                             // push registers
  ldr   r1, =LCD_RS                              // RS=1 for data
  bl    LCD_Write_Byte                           // write character
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Delay microseconds.
 *
 * @param   r0 - microseconds to delay
 * @retval  None
 */
.type Delay_US, %function
Delay_US:
  push  {r4-r12, lr}                             // push registers
  ldr   r4, =4                                   // loops per microsecond
  mul   r5, r0, r4                               // total loops
.Delay_US_Loop:
  subs  r5, r5, #1                               // decrement counter
  bne   .Delay_US_Loop                           // loop until zero
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Turn LCD backlight on.
 *
 * @param   None
 * @retval  None
 */
.global LCD_Backlight_On
.type LCD_Backlight_On, %function
LCD_Backlight_On:
  push  {r4-r12, lr}                             // push registers
  bl    I2C_Start                                // I2C start
  ldr   r0, =0x4E                                // I2C address 0x27 << 1 = 0x4E
  bl    I2C1_Write_Byte                          // write address
  ldr   r0, =0x08                                // backlight ON
  bl    I2C1_Write_Byte                          // write data
  bl    I2C_Stop                                 // I2C stop
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * @brief   Turn LCD backlight off.
 *
 * @param   None
 * @retval  None
 */
.global LCD_Backlight_Off
.type LCD_Backlight_Off, %function
LCD_Backlight_Off:
  push  {r4-r12, lr}                             // push registers
  bl    I2C_Start                                // I2C start
  ldr   r0, =0x4E                                // I2C address 0x27 << 1 = 0x4E
  bl    I2C1_Write_Byte                          // write address
  ldr   r0, =0x00                                // backlight OFF
  bl    I2C1_Write_Byte                          // write data
  bl    I2C_Stop                                 // I2C stop
  pop   {r4-r12, lr}                             // pop registers
  bx    lr                                       // return

/**
 * Test data and constants.
 * The .rodata section is used for constants and static data.
 */
.section .rodata                                 // read-only data section

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
