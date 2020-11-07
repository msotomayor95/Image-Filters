import pandas as pd

df1asm = pandas.read_csv("resultados_ReforzarBrillo1ASM.csv")
df1c = pandas.read_csv("resultados_ReforzarBrillo1C.csv")
df2c = pandas.read_csv("resultados_ReforzarBrillo2C.csv")
df3c = pandas.read_csv("resultados_ReforzarBrillo3C.csv")

# df1 = pandas.read_csv("resultados_ImagenFantasma1.csv")
# df2 = pandas.read_csv("resultados_ImagenFantasma2.csv")
# df3 = pandas.read_csv("resultados_ImagenFantasma3.csv")

# df1 = pandas.read_csv("resultados_ColorBordes1.csv")
# df2 = pandas.read_csv("resultados_ColorBordes2.csv")
# df3 = pandas.read_csv("resultados_ColorBordes3.csv")

res = []

for i in range(1, 101):
	res += ["{}x{}".format(32*i,18*i) for j in range(500)]

df1asm["resolucion"] = res
df1c["resolucion"] = res
df2c["resolucion"] = res
df3c["resolucion"] = res

df1asm = df1asm.groupby(["resolucion"], as_index=False).median()
df1c = df1c.groupby(["resolucion"], as_index=False).median()
df2c = df2c.groupby(["resolucion"], as_index=False).median()
df3c = df3c.groupby(["resolucion"], as_index=False).median()

df_resultado = pd.DataFrame()

df_resultados["ciclos ASM"] = df1asm["ciclos"]
df_resultados["ciclos -O0"] = df1c["ciclos"]
df_resultados["Ciclos -O2"] = df2c["ciclos"]
df_resultados["Ciclos -O3"] = df3c["ciclos"]
df_resultados["resolucion"] = df1asm["resolucion"]
# df_resultados["diferencia entre A y B"] = df1["ciclos"] - df2["ciclos"]

df_resultados.to_csv("resultados_nivel.csv")
