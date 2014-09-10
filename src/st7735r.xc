/*
 * st7735r.xc
 *
 *  Created on: Sep 8, 2014
 *      Author: Maksym Sditanov
 *  Ported of http://users.ece.utexas.edu/~valvano/arm/ST7735.c
 */
#include "st7735r.h"
#include <xclib.h>
#include <stdlib.h>
#include "st7735r_ascii_font.h"

const unsigned int st7735r_sclk_val = 0xAA;
const unsigned char st7735r_display_width = 128;
const unsigned char st7735r_display_height = 160;
const unsigned char st7735r_rowStart = 0;
const unsigned char st7735r_columnStart = 0;

static inline void st7735r_select(st7735r_interface &spi_if)
{
    spi_if.cs <: 0;
}

static inline void st7735r_unselect(st7735r_interface &spi_if)
{
    spi_if.cs <: 1;
}

void st7735r_port_init(st7735r_interface& spi_if, int spi_clock_div)
{
    configure_clock_rate(spi_if.blk1, 100, spi_clock_div);
    set_port_no_inv(spi_if.scl);
    configure_out_port(spi_if.scl, spi_if.blk1, 1);
    //sclk_val = 0xAA;

    configure_clock_src(spi_if.blk2, spi_if.scl);
    configure_out_port(spi_if.sda, spi_if.blk2, 0);

    configure_out_port(spi_if.rs, spi_if.blk1, 0);
    configure_out_port(spi_if.cs, spi_if.blk1, 0);

    clearbuf(spi_if.rs);
    clearbuf(spi_if.cs);

    clearbuf(spi_if.sda);
    clearbuf(spi_if.scl);
    start_clock(spi_if.blk1);
    start_clock(spi_if.blk2);
}

void st7735r_reset(st7735r_interface& spi_if)
{
    spi_if.reset <: 0;
    delay_microseconds(100);
    spi_if.reset <: 1;
    delay_microseconds(100);
}

static inline void st7735r_write(st7735r_interface &spi_if, unsigned char data, unsigned char isData)
{
    st7735r_select(spi_if);

    spi_if.rs <: isData;

    // MSb-first bit order - SPI standard
    unsigned x = bitrev(data) >> 24;

    spi_if.sda <: x;
    spi_if.scl <: st7735r_sclk_val;
    spi_if.scl <: st7735r_sclk_val;
    sync(spi_if.scl);

    st7735r_unselect(spi_if);
}

static inline void st7735r_write_nocs(st7735r_interface &spi_if, unsigned char data, unsigned char isData)
{
    spi_if.rs <: isData;

    // MSb-first bit order - SPI standard
    unsigned x = bitrev(data) >> 24;

    spi_if.sda <: x;
    spi_if.scl <: st7735r_sclk_val;
    spi_if.scl <: st7735r_sclk_val;
    sync(spi_if.scl);
}

// --------------------------------------------------------------------------------------------
// ported programm
// --------------------------------------------------------------------------------------------
static inline void st7735r_write_command(st7735r_interface& spi_if, unsigned char c)
{
    st7735r_write(spi_if, c, 0);
}

static inline void st7735r_write_data(st7735r_interface& spi_if, unsigned char d)
{
    st7735r_write(spi_if, d, 1);
}

static inline void st7735r_write_command_nocs(st7735r_interface& spi_if, unsigned char c)
{
    st7735r_write_nocs(spi_if, c, 0);
}

static inline void st7735r_write_data_nocs(st7735r_interface& spi_if, unsigned char d)
{
    st7735r_write_nocs(spi_if, d, 1);
}


void st7735r_init(st7735r_interface& spi_if)
{
    st7735r_port_init(spi_if, 100);
    st7735r_reset(spi_if);

    st7735r_write_command(spi_if, 0x11);//Sleep exit
    delay_microseconds(120);

    //ST7735R Frame Rate
    st7735r_write_command(spi_if, 0xB1);
    st7735r_write_data(spi_if, 0x01); st7735r_write_data(spi_if, 0x2C); st7735r_write_data(spi_if, 0x2D);
    st7735r_write_command(spi_if, 0xB2);
    st7735r_write_data(spi_if, 0x01); st7735r_write_data(spi_if, 0x2C); st7735r_write_data(spi_if, 0x2D);
    st7735r_write_command(spi_if, 0xB3);
    st7735r_write_data(spi_if, 0x01); st7735r_write_data(spi_if, 0x2C); st7735r_write_data(spi_if, 0x2D);
    st7735r_write_data(spi_if, 0x01); st7735r_write_data(spi_if, 0x2C); st7735r_write_data(spi_if, 0x2D);

    st7735r_write_command(spi_if, 0xB4); //Column inversion
    st7735r_write_data(spi_if, 0x07);

    //ST7735R Power Sequence
    st7735r_write_command(spi_if,0xC0);
    st7735r_write_data(spi_if, 0xA2); st7735r_write_data(spi_if, 0x02); st7735r_write_data(spi_if, 0x84);
    st7735r_write_command(spi_if, 0xC1); st7735r_write_data(spi_if, 0xC5);
    st7735r_write_command(spi_if, 0xC2);
    st7735r_write_data(spi_if, 0x0A); st7735r_write_data(spi_if, 0x00);
    st7735r_write_command(spi_if, 0xC3);
    st7735r_write_data(spi_if, 0x8A); st7735r_write_data(spi_if, 0x2A);
    st7735r_write_command(spi_if, 0xC4);
    st7735r_write_data(spi_if, 0x8A); st7735r_write_data(spi_if, 0xEE);

    st7735r_write_command(spi_if, 0xC5); //VCOM
    st7735r_write_data(spi_if, 0x0E);

    st7735r_write_command(spi_if, 0x36); //MX, MY, RGB mode
    st7735r_write_data(spi_if, 0xC8);

    //ST7735R Gamma Sequence
    st7735r_write_command(spi_if, 0xe0);
    st7735r_write_data(spi_if, 0x0f); st7735r_write_data(spi_if, 0x1a);
    st7735r_write_data(spi_if, 0x0f); st7735r_write_data(spi_if, 0x18);
    st7735r_write_data(spi_if, 0x2f); st7735r_write_data(spi_if, 0x28);
    st7735r_write_data(spi_if, 0x20); st7735r_write_data(spi_if, 0x22);
    st7735r_write_data(spi_if, 0x1f); st7735r_write_data(spi_if, 0x1b);
    st7735r_write_data(spi_if, 0x23); st7735r_write_data(spi_if, 0x37); st7735r_write_data(spi_if, 0x00);

    st7735r_write_data(spi_if, 0x07);
    st7735r_write_data(spi_if, 0x02); st7735r_write_data(spi_if, 0x10);
    st7735r_write_command(spi_if, 0xe1);
    st7735r_write_data(spi_if, 0x0f); st7735r_write_data(spi_if, 0x1b);
    st7735r_write_data(spi_if, 0x0f); st7735r_write_data(spi_if, 0x17);
    st7735r_write_data(spi_if, 0x33); st7735r_write_data(spi_if, 0x2c);
    st7735r_write_data(spi_if, 0x29); st7735r_write_data(spi_if, 0x2e);
    st7735r_write_data(spi_if, 0x30); st7735r_write_data(spi_if, 0x30);
    st7735r_write_data(spi_if, 0x39); st7735r_write_data(spi_if, 0x3f);
    st7735r_write_data(spi_if, 0x00); st7735r_write_data(spi_if, 0x07);
    st7735r_write_data(spi_if, 0x03); st7735r_write_data(spi_if, 0x10);

    st7735r_write_command(spi_if, 0x2a);
    st7735r_write_data(spi_if, 0x00);st7735r_write_data(spi_if, 0x00);
    st7735r_write_data(spi_if, 0x00);st7735r_write_data(spi_if, 0x7f);
    st7735r_write_command(spi_if, 0x2b);
    st7735r_write_data(spi_if, 0x00);st7735r_write_data(spi_if, 0x00);
    st7735r_write_data(spi_if, 0x00);st7735r_write_data(spi_if, 0x9f);

    st7735r_write_command(spi_if, 0xF0); //Enable test command
    st7735r_write_data(spi_if, 0x01);
    st7735r_write_command(spi_if, 0xF6); //Disable ram power save mode
    st7735r_write_data(spi_if, 0x00);

    st7735r_write_command(spi_if, 0x3A); //65k mode
    st7735r_write_data(spi_if, 0x05);


    st7735r_write_command(spi_if, 0x29);//Display on
}

void st7735r_shutdown(st7735r_interface &spi_if)
{
    set_clock_off(spi_if.blk2);
    set_clock_off(spi_if.blk1);
    set_port_use_off(spi_if.sda);
    set_port_use_off(spi_if.rs);
    set_port_use_off(spi_if.scl);
}

void static st7735r_setAddrWindow(st7735r_interface &spi_if, unsigned char x0, unsigned char y0, unsigned char x1, unsigned char y1)
{
    if (x0 >= st7735r_display_width || x1 >= st7735r_display_width) return;
    if (y0 >= st7735r_display_height || y1 >= st7735r_display_height) return;

    st7735r_select(spi_if);

    st7735r_write_command_nocs(spi_if, 0x2A);                        // Column addr set
    st7735r_write_data_nocs(spi_if, 0x00);
    st7735r_write_data_nocs(spi_if, x0 + st7735r_columnStart);       // XSTART
    st7735r_write_data_nocs(spi_if, 0x00);
    st7735r_write_data_nocs(spi_if, x1 + st7735r_columnStart);       // XEND

    st7735r_write_command_nocs(spi_if, 0x2B); // Row addr set
    st7735r_write_data_nocs(spi_if, 0x00);
    st7735r_write_data_nocs(spi_if, y0 + st7735r_rowStart);          // YSTART
    st7735r_write_data_nocs(spi_if, 0x00);
    st7735r_write_data_nocs(spi_if, y1 + st7735r_rowStart);          // YEND

    st7735r_write_command_nocs(spi_if, 0x2C);                        // write to RAM

    st7735r_unselect(spi_if);
}

// Send two bytes of data, most significant byte first
// Requires 2 bytes of transmission
void static st7735r_pushColor(st7735r_interface &spi_if, unsigned short color)
{
    st7735r_select(spi_if);
    st7735r_write_data_nocs(spi_if, (unsigned char)(color >> 8));
    st7735r_write_data_nocs(spi_if, (unsigned char)color);
    st7735r_unselect(spi_if);
}

void st7735r_draw_pixel(st7735r_interface& spi_if, unsigned char x, unsigned char y, unsigned short color)
{
    st7735r_setAddrWindow(spi_if, x, y, x+1, y+1);
    st7735r_pushColor(spi_if, color);
}

unsigned short st7735r_color565(unsigned char r, unsigned char g, unsigned char b)
{
    return ((b & 0xF8) << 8) | ((g & 0xFC) << 3) | (r >> 3);
}

void st7735r_drawFastVLine(st7735r_interface& spi_if, short x, short y, short h, unsigned short color)
{
    unsigned char hi = color >> 8, lo = color;

    // Rudimentary clipping
    if( (x >= st7735r_display_width) || (y >= st7735r_display_height)) return;
    if( (y+h-1) >= st7735r_display_height)
        h = st7735r_display_height - y;

    st7735r_setAddrWindow(spi_if, x, y, x, y+h-1);

    hi = color >> 8;
    lo = color;

    while (h--) {
        st7735r_write_data(spi_if, hi);
        st7735r_write_data(spi_if, lo);
    }
}

void st7735r_drawFastHLine(st7735r_interface& spi_if, short x, short y, short w, unsigned short color)
{
    unsigned char hi = color >> 8, lo = color;

    // Rudimentary clipping
    if((x >= st7735r_display_width) || (y >= st7735r_display_height)) return;
    if((x+w-1) >= st7735r_display_width)
        w = st7735r_display_width-x;

    st7735r_setAddrWindow(spi_if, x, y, x+w-1, y);

    while (w--) {
        st7735r_write_data(spi_if, hi);
        st7735r_write_data(spi_if, lo);
    }
}

void st7735r_fillRect(st7735r_interface& spi_if, short x, short y, short w, short h, unsigned short color)
{
    unsigned char hi = color >> 8, lo = color;

    // rudimentary clipping (drawChar w/big text requires this)
    if ((x >= st7735r_display_width) || (y >= st7735r_display_height)) return;

    if ((x + w - 1) >= st7735r_display_width)
        w = st7735r_display_width  - x;
    if ((y + h - 1) >= st7735r_display_height)
        h = st7735r_display_height - y;

    st7735r_setAddrWindow(spi_if, x, y, x+w-1, y+h-1);

    for(y=h; y>0; y--) {
        for(x=w; x>0; x--) {
            st7735r_write_data(spi_if, hi);
            st7735r_write_data(spi_if, lo);
        }
    }
}

void st7735r_fillScreen(st7735r_interface& spi_if, unsigned short color)
{
    st7735r_fillRect(spi_if, 0, 0, st7735r_display_width, st7735r_display_height, color);
}

void st7735r_sync(st7735r_interface& spi_if)
{
    st7735r_write_command(spi_if, 0x2C);    // memwrite
}

inline static void st7735r_swap(short& a, short& b)
{
    int x = a;
    a = b;
    b = x;
}

void st7735r_drawLine(st7735r_interface& spi_if, short x0, short y0, short x1, short y1, unsigned short color)
{
    short steep = abs(y1 - y0) > abs(x1 - x0);
    if (steep) {
        st7735r_swap(x0, y0);
        st7735r_swap(x1, y1);
    }
    if (x0 > x1) {
        st7735r_swap(x0, x1);
        st7735r_swap(y0, y1);
    }
    short dx, dy;
    dx = x1 - x0;
    dy = abs(y1 - y0);
    short err = dx / 2;
    short ystep;
    if (y0 < y1) {
        ystep = 1;
    } else {
        ystep = -1;
    }
    for (; x0 <= x1; x0++) {
        if (steep) {
            st7735r_draw_pixel(spi_if, y0, x0, color);
        } else {
            st7735r_draw_pixel(spi_if, x0, y0, color);
        }
        err -= dy;
        if (err < 0) {
            y0 += ystep;
            err += dx;
        }
    }
}

void st7735r_drawCharS(st7735r_interface& spi_if, short x, short y, unsigned char c, short textColor, short bgColor, unsigned char size)
{
    unsigned char line; // vertical column of pixels of character in font
    char i, j;
    if((x >= st7735r_display_width)            || // Clip right
            (y >= st7735r_display_height)           || // Clip bottom
            ((x + 5 * size - 1) < 0) || // Clip left
            ((y + 8 * size - 1) < 0))   // Clip top
        return;

    for (i=0; i<6; i++ ) {
        if (i == 5)
            line = 0x0;
        else
            line = st7735r_ascii_font[(c*5)+i];

        for (j = 0; j<8; j++) {
            if (line & 0x1) {
                if (size == 1) // default size
                    st7735r_draw_pixel(spi_if, x+i, y+j, textColor);
                else {  // big size
                    st7735r_fillRect(spi_if, x+(i*size), y+(j*size), size, size, textColor);
                }
            } else if (bgColor != textColor) {
                if (size == 1) // default size
                    st7735r_draw_pixel(spi_if, x+i, y+j, bgColor);
                else {  // big size
                    st7735r_fillRect(spi_if, x+i*size, y+j*size, size, size, bgColor);
                }
            }
            line >>= 1;
        }
    }
}

void st7735r_drawCharFast(st7735r_interface& spi_if, short x, short y, unsigned char c, short textColor, short bgColor, unsigned char size)
{
    unsigned char line; // horizontal row of pixels of character
    char col, row, i, j;// loop indices
    if(  ((x + 5*size - 1) >= st7735r_display_width)    || // Clip right
         ((y + 8*size - 1) >= st7735r_display_height)   || // Clip bottom
         ((x + 5*size - 1) < 0)                         || // Clip left
         ((y + 8*size - 1) < 0))                           // Clip top
    {
        return;
    }

    st7735r_setAddrWindow(spi_if, x, y, x+6*size-1, y+8*size-1);

    line = 0x01;        // print the top row first
    // print the rows, starting at the top
    for(row=0; row<8; row=row+1){
        for(i=0; i<size; i=i+1){
            // print the columns, starting on the left
            for(col=0; col<5; col=col+1){
                if(st7735r_ascii_font[(c*5)+col]&line){
                    // bit is set in Font, print pixel(s) in text color
                    for(j=0; j<size; j=j+1){
                        st7735r_pushColor(spi_if, textColor);
                    }
                } else{
                    // bit is cleared in Font, print pixel(s) in background color
                    for(j=0; j<size; j=j+1){
                        st7735r_pushColor(spi_if, bgColor);
                    }
                }
            }
            // print blank column(s) to the right of character
            for(j=0; j<size; j=j+1){
                st7735r_pushColor(spi_if, bgColor);
            }
        }
        line = line<<1;   // move up to the next row
    }
}

//------------ST7735_DrawBitmap------------
// Displays a 16-bit color BMP image.  A bitmap file that is created
// by a PC image processing program has a header and may be padded
// with dummy columns so the data have four byte alignment.  This
// function assumes that all of that has been stripped out, and the
// array image[] has one 16-bit halfword for each pixel to be
// displayed on the screen (encoded in reverse order, which is
// standard for bitmap files).  An array can be created in this
// format from a 24-bit-per-pixel .bmp file using the associated
// converter program.
// (x,y) is the screen location of the lower left corner of BMP image
// Requires (11 + 2*w*h) bytes of transmission (assuming image fully on screen)
// Input: x     horizontal position of the bottom left corner of the image, columns from the left edge
//        y     vertical position of the bottom left corner of the image, rows from the top edge
//        image pointer to a 16-bit color BMP image
//        w     number of pixels wide
//        h     number of pixels tall
// Output: none
// Must be less than or equal to 128 pixels wide by 160 pixels high
void st7735r_drawBitmap(st7735r_interface& spi_if, short x, short y, const unsigned short *image, short w, short h)
{
    short skipC=0;                        // non-zero if columns need to be skipped due to clipping
    short originalWidth = w;              // save this value; even if not all columns fit on the screen, the image is still this width in ROM
    int i = w*(h - 1);

    if((x >= st7735r_display_width) || ((y - h + 1) >= st7735r_display_height) || ((x + w) <= 0) || (y < 0)){
        return;                             // image is totally off the screen, do nothing
    }

    if((w > st7735r_display_width) || (h > st7735r_display_height)){    // image is too wide for the screen, do nothing
        //***This isn't necessarily a fatal error, but it makes the
        //following logic much more complicated, since you can have
        //an image that exceeds multiple boundaries and needs to be
        //clipped on more than one side.
        return;
    }

    if((x + w - 1) >= st7735r_display_width){            // image exceeds right of screen
        skipC = (x + w) - st7735r_display_width;           // skip cut off columns
        w = st7735r_display_width - x;
    }

    if((y - h + 1) < 0) {                  // image exceeds top of screen
        i = i - (h - y - 1) * originalWidth;  // skip the last cut off rows
        h = y + 1;
    }

    if(x < 0) {                            // image exceeds left of screen
        w = w + x;
        skipC = -1*x;                       // skip cut off columns
        i = i - x;                          // skip the first cut off columns
        x = 0;
    }

    if(y >= st7735r_display_height){                     // image exceeds bottom of screen
        h = h - (y - st7735r_display_height + 1);
        y = st7735r_display_height - 1;
    }

    st7735r_setAddrWindow(spi_if, x, y-h+1, x+w-1, y);

    for(y=0; y<h; y=y+1){
        for(x=0; x<w; x=x+1) {
                                        // send the top 8 bits
            st7735r_write_data(spi_if, (unsigned char)(image[i] >> 8));
                                        // send the bottom 8 bits
            st7735r_write_data(spi_if, (unsigned char)image[i]);
            i = i + 1;                        // go to the next pixel
        }

        i = i + skipC;
        i = i - 2*originalWidth;
    }
}
