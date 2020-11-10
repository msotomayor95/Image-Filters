import pandas
import matplotlib.pyplot as plt

# df1asm = pandas.read_csv("resultados_ReforzarBrillo1.csv")
# df2asm = pandas.read_csv("resultados_ReforzarBrillo2.csv")

df1asm = pandas.read_csv("resultados_ImagenFantasma1.csv")
df2asm = pandas.read_csv("resultados_ImagenFantasma2.csv")

res = []

for i in range(1, 101):
	res += [ i for j in range(500)]

df1asm["resolucion"] = res
df2asm["resolucion"] = res

df1asm = df1asm.groupby(["resolucion"], as_index=False).median()
df2asm = df2asm.groupby(["resolucion"], as_index=False).median()

df_resultados = pandas.DataFrame()

df_resultados["ASM1"] = df1asm["ciclos"]
df_resultados["ASM2"] = df2asm["ciclos"]
df_resultados["resolucion"] = df1asm["resolucion"]
# df_resultados["diferencia entre A y B"] = df1asm["ciclos"] - df2asm["ciclos"]

plt.figure(figsize=(12,6))
plt.plot(df_resultados["resolucion"], df_resultados["ASM1"], label="Original")
plt.plot(df_resultados["resolucion"], df_resultados["ASM2"], label="Con Accesos a memoria")

plt.ylabel("Ticks de Reloj")
plt.xlabel("i")

plt.legend(loc="upper left")

plt.ticklabel_format(style="plain")

plt.show()

# df_resultados.to_csv("resultados_finales_reforzarBrillo.csv")
# df_resultados.to_csv("resultados_finales_ImagenFantasma.csv")

# plt.figure(figsize=(12,6))

# plt.boxplot(df_resultados['diferencia entre A y B'])


# plt.show()

# plt.yscale('log')

# fig.xlabel('i')
# fig.ylabel('Ticks de Reloj')

# plt.title("Reforzar Brillo")
# plt.title("Imagen Fantasma")
# plt.title("Color Bordes")

# plt.savefig("comparacio_c_vs_asm.png")
# plt.savefig('reforzar_brillo.png')
# plt.savefig('imagen_fantasma.png')
# plt.savefig('color_bordes.png')