
#include <stdio.h>
#include <string.h>

#include "../tp2.h"

void monocromatizar_inf_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

void monocromatizar_inf_c    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

typedef void (monocromatizar_inf_fn_t) (unsigned char*, unsigned char*, int, int, int, int);


void leer_params_monocromatizar_inf(configuracion_t *config, int argc, char *argv[]) {

}

void aplicar_monocromatizar_inf(configuracion_t *config)
{
	monocromatizar_inf_fn_t *monocromatizar_inf = SWITCH_C_ASM ( config, monocromatizar_inf_c, monocromatizar_inf_asm ) ;
	buffer_info_t info = config->src;
	monocromatizar_inf(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding);

}

void ayuda_monocromatizar_inf()
{
	printf ( "       * monocromatizar_inf\n" );
	printf ( "           Parámetros     : \n"
	         "                         no tiene\n");
	printf ( "           Ejemplo de uso : \n"
	         "                         monocromatizar_inf -i c facil.bmp\n" );
}

DEFINIR_FILTRO(monocromatizar_inf)

