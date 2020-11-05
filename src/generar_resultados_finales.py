import pandas as pd

df1 = pandas.read_csv("resultados_ReforzarBrillo1.csv")
df2 = pandas.read_csv("resultados_ReforzarBrillo2.csv")
df3 = pandas.read_csv("resultados_ReforzarBrillo3.csv")

# df1 = pandas.read_csv("resultados_ImagenFantasma1.csv")
# df2 = pandas.read_csv("resultados_ImagenFantasma2.csv")
# df3 = pandas.read_csv("resultados_ImagenFantasma3.csv")

# df1 = pandas.read_csv("resultados_ColorBordes1.csv")
# df2 = pandas.read_csv("resultados_ColorBordes2.csv")
# df3 = pandas.read_csv("resultados_ColorBordes3.csv")

res = []

for i in range(1, 101):
	res += ["{}x{}".format(32*i,18*i) for j in range(500)]

df1 = df1.groupby(["resolucion"], as_index=False).median()
df2 = df2.groupby(["resolucion"], as_index=False).median()
df3 = df3.groupby(["resolucion"], as_index=False).median()

df_resultado = pd.DataFrame()

df_resultados["ciclos A"] = df1["ciclos"]
df_resultados["ciclos B"] = df2["ciclos"]
df_resultados["Ciclos C"] = df3["ciclos"]
df_resultados["resolucion"] = df1["resolucion"]
# df_resultados["diferencia entre A y B"] = df1["ciclos"] - df2["ciclos"]

df_resultados.to_csv("resultados_nivel.csv")
