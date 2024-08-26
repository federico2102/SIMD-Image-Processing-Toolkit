#include "../tp2.h"
#define max(a, b) ((a)>(b))?(a):(b)

void monocromatizar_inf_c (
	unsigned char *src, 
	unsigned char *dst, 
	int width, 
	int height, 
	int src_row_size, 
	int dst_row_size
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
	for(int i = 0; i < width*4; i += 4){
		for(int j = 0; j < height; j++){
			bgra_t *src_pixel = (bgra_t*)&src_matrix[j][i];
			unsigned char componente_max = max(max(src_pixel->r, src_pixel->g), src_pixel->b);
			bgra_t *dst_pixel = (bgra_t*)&dst_matrix[j][i];
			dst_pixel->a = src_pixel->a;
			dst_pixel->r = componente_max;
			dst_pixel->g = componente_max;
			dst_pixel->b = componente_max;
		}
	}
}
