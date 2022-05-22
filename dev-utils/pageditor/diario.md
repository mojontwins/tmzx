## 20220522

Quiero hacer un remake de uno de mis primeros juegos de Spectrum pero dándole la jugabilidad que entonces no era capaz de darle - pero eso no importa ahora, lo que importa es que necesito que las pantallas tengan gráficos de bloque con textos y ya no tengo 11 años y no me apetece tener que picarlos a mano en el editor ZX, así que voy a modificar **pageditor** para que pueda exportar rectángulos arbitrarios a sentencias PRINT que luego pueda enganchar en un fuente y convertir a ZX con bas2tap o algo parecido.

Antes de ponerme a programar tengo que ver cómo maneja bas2tap los códigos para bloques gráficos, caracteres de control y atributos. Tengo que ver si es viable exportar en un string un rectángulo arbitrario metiendo saltos de linea.

