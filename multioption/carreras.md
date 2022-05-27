# Carreras de Coches

Motor: 

El motor debe reaccionar a los valores numéricos asociados a cada opción, que pueden ser:

* -1: Coche dañado, 5 turnos para entrar en boxes, si no coche destruído.
* -2: Coche destruido (con mensaje)
* 1: Avanza una casilla
* 2: Avanza dos casillas
* 3: Avanza tres casillas
* 10: Avanza 1+(RND*3) casillas (de 1 a 3).
* 20: 25% sale bien (2 casillas), 25% normal (1 casilla), 50% dañado (con mensaje).
* 30: 50% sale bien (2 casillas), 25% normal (1 casilla), 25% dañado (con mensaje).
* 40: 50% sale bien (2), 50% normal (2)

Boxes: retrocede 5 casillas.

Variables:
	D=1: Coche dañado, E=5...0 energía.
	O(3): Los resultados de cada opción
	M$: El texto del mensaje dañado
	T$: El texto del mensaje muerte

Lineas
	10: Parser
	50: Inicio del juego
    N*100: casilla N
    9700: Boxes
    9800: Damage
    9900: Game over

Lista de pantallas (al menos 25)

1
¡EMPIEZA LA CARRERA! SE APROXIMA LA PRIMERA CURVA
1.¡FRENA!(1)
2.DEJA DE ACELERAR(2)
3.¡A TODA MAQUINA!(-2 PEYEJAZO MORTAL! TU COCHE PARECE UN ACORDEON)


2
EN LA RECTA TRATA DE ADELANTARTE YIM
1.GRITALE(1)
2.PONTE DELANTE!(2)
3.NO HAGAS NADA(40)


3
VIA LIBRE! AHORA NO TIENES COCHES DELANTE
1.A TODO GAS!(30 - "EN EL ULTIMO MOMENTO APARECE EL CORREDOR POLACO Y CHOCAIS!")
2.TRANQUI PERO SEGURO(1)
3.VOLANTAZO A LA DERECHA (-2 PEYEJAZO MORTAL! TU COCHE PARECE UN ACORDEON)