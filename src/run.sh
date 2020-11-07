#!/bin/bash

#ReforzarBrillo
echo "ciclos" >> resultados_ReforzarBrillo1.csv
# echo "ciclos" >> resultados_ReforzarBrillo2.csv
# echo "ciclos" >> resultados_ReforzarBrillo3.csv

#ImagenFantasma
# echo "ciclos" >> resultados_ImagenFantasma1C.csv
# echo "ciclos" >> resultados_ImagenFantasma2.csv
# echo "ciclos" >> resultados_ImagenFantasma3.csv

#ColorBordes
# echo "ciclos" >> resultados_ColorBordes1.csv
# echo "ciclos" >> resultados_ColorBordes2.csv
# echo "ciclos" >> resultados_ColorBordes3.csv

echo "Creando casos de prueba"
cd tests/

python3 1_generar_imagenes.py

cd ../
echo "Corriendo casos de prueba"

for i in {1..100}
do
	./build/tp2 ReforzarBrillo -i asm -t 500 tests/data/imagenes_a_testear/SweetNovember.$i.bmp 100 50 50 50
	# ./build/tp2 ImagenFantasma -i asm -t 500 tests/data/imagenes_a_testear/SweetNovember.$i.bmp 1 1
	# ./build/tp2 ColorBordes -i asm -t 500 tests/data/imagenes_a_testear/SweetNovember.$i.bmp
done

rm tests/data/imagenes_a_testear/*
rm *.bmp
