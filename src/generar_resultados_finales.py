import pandas
import matplotlib.pyplot as plt

# df1asm = pandas.read_csv("resultados_ReforzarBrillo1ASM.csv")
# df1c = pandas.read_csv("resultados_ReforzarBrillo1C.csv")
# df2c = pandas.read_csv("resultados_ReforzarBrillo2C.csv")
# df3c = pandas.read_csv("resultados_ReforzarBrillo3C.csv")

df1asm = pandas.read_csv("resultados_ImagenFantasma1ASM.csv")
df1c = pandas.read_csv("resultados_ImagenFantasma1C.csv")
df2c = pandas.read_csv("resultados_ImagenFantasma2C.csv")
df3c = pandas.read_csv("resultados_ImagenFantasma3C.csv")

# df1asm = pandas.read_csv("resultados_ColorBordes1ASM.csv")
# df1c = pandas.read_csv("resultados_ColorBordes1C.csv")
# df2c = pandas.read_csv("resultados_ColorBordes2C.csv")
# df3c = pandas.read_csv("resultados_ColorBordes3C.csv")

res = []

for i in range(1, 101):
	res += [ i for j in range(500)]

df1asm["resolucion"] = res
df1c["resolucion"] = res
df2c["resolucion"] = res
df3c["resolucion"] = res

df1asm = df1asm.groupby(["resolucion"], as_index=False).median()
df1c = df1c.groupby(["resolucion"], as_index=False).median()
df2c = df2c.groupby(["resolucion"], as_index=False).median()
df3c = df3c.groupby(["resolucion"], as_index=False).median()

df_resultados = pandas.DataFrame()

df_resultados["ASM"] = df1asm["ciclos"]
df_resultados["O0"] = df1c["ciclos"]
df_resultados["O2"] = df2c["ciclos"]
df_resultados["O3"] = df3c["ciclos"]
df_resultados["resolucion"] = df1asm["resolucion"]
# df_resultados["diferencia entre A y B"] = df1["ciclos"] - df2["ciclos"]


fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(12,6))

ax1.plot(df_resultados['resolucion'], df_resultados['ASM'], label= "ASM")
ax1.plot(df_resultados['resolucion'], df_resultados['O0'], label= "C con flag -O0")
ax1.plot(df_resultados['resolucion'], df_resultados['O2'], label= "C con flag -O2")
ax1.plot(df_resultados['resolucion'], df_resultados['O3'], label= "C con flag -O3")

ax2.plot(df_resultados['resolucion'], df_resultados['ASM'], label= "ASM")
ax2.plot(df_resultados['resolucion'], df_resultados['O0'], label= "C con flag -O0")
ax2.plot(df_resultados['resolucion'], df_resultados['O2'], label= "C con flag -O2")
ax2.plot(df_resultados['resolucion'], df_resultados['O3'], label= "C con flag -O3")

ax3.plot(df_resultados['resolucion'], df_resultados['ASM'], label= "ASM")
ax3.plot(df_resultados['resolucion'], df_resultados['O0'], label= "C con flag -O0")
ax3.plot(df_resultados['resolucion'], df_resultados['O2'], label= "C con flag -O2")
ax3.plot(df_resultados['resolucion'], df_resultados['O3'], label= "C con flag -O3")

ax1.set_ylabel("Ticks de Reloj")
ax1.set_xlabel("i")
ax1.legend(loc="upper left")
# ax1.set_yscale('log')

ax2.set_ylabel("Ticks de Reloj")
ax2.set_xlabel("i")
ax2.legend(loc="upper left")
# ax2.set_yscale('log')

ax3.set_ylabel("Ticks de Reloj")
ax3.set_xlabel("i")
ax3.legend(loc="upper left")
# ax3.set_yscale('log')

# fig.xlabel('i')
# fig.ylabel('Ticks de Reloj')

ax1.ticklabel_format(style="plain")
ax2.ticklabel_format(style="plain")
ax3.ticklabel_format(style="plain")

# fig.legend(loc="upper left")

ax1.title.set_text("Reforzar Brillo")
ax2.title.set_text("Imagen Fantasma")
ax3.title.set_text("Color Bordes")

fig.tight_layout(pad=2.5)

plt.savefig("comparacio_c_vs_asm.png")
# plt.savefig('reforzar_brillo.png')
# plt.savefig('imagen_fantasma.png')
# plt.savefig('color_bordes.png')