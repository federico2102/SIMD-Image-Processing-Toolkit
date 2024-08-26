
#include <stdio.h>
#include <string.h>

#include "../tp2.h"

void blit_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
					int src_row_size, int dst_row_size,
					unsigned char *blit, int bw, int bh, int b_row_size);

void blit_c    (unsigned char *src, unsigned char *dst, int cols, int filas,
                    int src_row_size, int dst_row_size,
					unsigned char *blit, int bw, int bh, int b_row_size);

typedef void (blit_fn_t) (unsigned char*, unsigned char*, int, int, int, int,
					unsigned char *, int, int, int);


void leer_params_blit(configuracion_t *config, int argc, char *argv[])
{
	config->archivo_entrada_2 = "img/blitsmall.bmp"; //argv[argc - 2];
}

void aplicar_blit(configuracion_t *config)
{
	blit_fn_t *blit = SWITCH_C_ASM ( config, blit_c, blit_asm ) ;
	buffer_info_t info = config->src;
	buffer_info_t info_blit = config->src_2;

	blit(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding,
			 info_blit.bytes, info_blit.width, info_blit.height, info_blit.width_with_padding);

}

void ayuda_blit()
{
	printf ( "       * blit\n" );
	printf ( "           Parámetros     : \n"
	         "                         no tiene\n");
	printf ( "           Ejemplo de uso : \n"
	         "                         blit -i c facil.bmp\n" );
}

DEFINIR_FILTRO(blit)




