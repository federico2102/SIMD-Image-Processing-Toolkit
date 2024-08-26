#include <stdio.h>
#include "../tp2.h"
void blit_c (unsigned char *src, unsigned char *dst, int w, int h, int src_row_size, int dst_row_size, unsigned char *blit, int bw, int bh, int b_row_size) {
	//COMPLETAR
	bgra_t (*matrix_src)[w] = (bgra_t (*)[w]) src;
    bgra_t (*matrix_dst)[w] = (bgra_t (*)[w]) dst;
    bgra_t (*matrix_blit)[bw] = (bgra_t (*)[bw]) blit;

	    for(int i=0; i<h; ++i){ //Con i recorro filas

		    	for(int j=0; j<w; ++j){ //Con j recorro columnas
		    
		    		if(w-bw >= 0 && h-bh >= 0 && h-bh-i <= 0 && w-bw-j <= 0){ 	//Si estoy en la esquina superior derecha y la imagen es mas grande o igual a la de peron
		    			int pbh = 0-(h-bh-i); //Pixel blit height (en que fila de blit estoy)
		    			int pbw = 0-(w-bw-j);	//Pixel blit width

		    			if(matrix_blit[pbh][pbw].r != 255 || matrix_blit[pbh][pbw].g != 0 || matrix_blit[pbh][pbw].b != 255){ 	//Si no es color magenta
		    				matrix_dst[i][j] = matrix_blit[pbh][pbw];
		    			} else {
		    				matrix_dst[i][j] = matrix_src[i][j];
		    			}
		    		} else {
		    			matrix_dst[i][j] = matrix_src[i][j];
		    		}
		    	}
	    }
}
