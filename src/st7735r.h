/*
 * st7735r.h
 *
 *  Created on: Sep 8, 2014
 *      Author: Maksym Sditanov
 */

#ifndef ST7735R_H_
#define ST7735R_H_

#include <xs1.h>

typedef struct st7735r_interface
{
    clock blk1;
    clock blk2;

    out buffered port:1 cs;
    out port reset;
    out buffered port:1 rs;
    out buffered port:8 sda;
    out buffered port:8 scl;

} st7735r_interface;

void st7735r_init(st7735r_interface& spi_if);
void st7735r_shutdown(st7735r_interface &spi_if);
void st7735r_sync(st7735r_interface& spi_if);
void st7735r_draw_pixel(st7735r_interface& spi_if, unsigned char x, unsigned char y, unsigned short color);
void st7735r_drawFastVLine(st7735r_interface& spi_if, short x, short y, short h, unsigned short color);
void st7735r_drawFastHLine(st7735r_interface& spi_if, short x, short y, short w, unsigned short color);
void st7735r_drawLine(st7735r_interface& spi_if, short x0, short y0, short x1, short y1, unsigned short color);
void st7735r_fillRect(st7735r_interface& spi_if, short x, short y, short w, short h, unsigned short color);
void st7735r_fillScreen(st7735r_interface& spi_if, unsigned short color);
void st7735r_drawCharFast(st7735r_interface& spi_if, short x, short y, unsigned char c, short textColor, short bgColor, unsigned char size);
void st7735r_drawBitmap(st7735r_interface& spi_if, short x, short y, const unsigned short *image, short w, short h);
unsigned short st7735r_color565(unsigned char r, unsigned char g, unsigned char b);


#endif /* ST7735R_H_ */
