// Power Query (M) used in excel/Retail_ABC_XYZ_Analysis.xlsx.
// Source: 'Online Retail.xlsx' from the UCI Machine Learning Repository (dataset 352).
// Change the path in Sales_clean > Origen to where you saved that file.
// Step names are in Spanish because they come from a Spanish-language Excel.

section Section1;

shared Sales_clean = let
    Origen = Excel.Workbook(File.Contents("C:\path\to\Online Retail.xlsx"), null, true),
    #"Online Retail_Sheet" = Origen{[Item="Online Retail",Kind="Sheet"]}[Data],
    #"Encabezados promovidos" = Table.PromoteHeaders(#"Online Retail_Sheet", [PromoteAllScalars=true]),
    #"Tipo cambiado" = Table.TransformColumnTypes(#"Encabezados promovidos",{{"InvoiceNo", type text}, {"StockCode", type text}, {"Description", type text}, {"Quantity", Int64.Type}, {"InvoiceDate", type datetime}, {"UnitPrice", type number}, {"CustomerID", Int64.Type}, {"Country", type text}}),
    #"Texto en mayúsculas" = Table.TransformColumns(#"Tipo cambiado",{{"StockCode", Text.Upper, type text}}),
    #"Filas filtradas" = Table.SelectRows(#"Texto en mayúsculas", each [UnitPrice] > 0),
    #"Personalizada agregada" = Table.AddColumn(#"Filas filtradas", "Is product", each Text.Length(Text.Select(Text.Start([StockCode], 5), {"0".."9"})) = 5),
    #"Tipo cambiado1" = Table.TransformColumnTypes(#"Personalizada agregada",{{"Is product", type logical}}),
    #"Filas filtradas1" = Table.SelectRows(#"Tipo cambiado1", each ([Is product] = true)),
    #"Columnas quitadas" = Table.RemoveColumns(#"Filas filtradas1",{"Is product"}),
    #"Personalizada agregada1" = Table.AddColumn(#"Columnas quitadas", "Revenue", each [Quantity] * [UnitPrice]),
    #"Tipo cambiado2" = Table.TransformColumnTypes(#"Personalizada agregada1",{{"Revenue", type number}}),
    #"Filas filtradas2" = Table.SelectRows(#"Tipo cambiado2", each [InvoiceNo] <> "556444" and [InvoiceNo] <> "556446")
in
    #"Filas filtradas2";

shared Products = let
    Origen = Sales_clean,
    #"Filas agrupadas" = Table.Group(Origen, {"StockCode"}, {{"Revenue", each List.Sum([Revenue]), type nullable number}, {"Units", each List.Sum([Quantity]), type nullable number}, {"Description", each List.Max([Description]), type nullable text}}),
    #"Tipo cambiado" = Table.TransformColumnTypes(#"Filas agrupadas",{{"Units", Int64.Type}}),
    #"Filas ordenadas" = Table.Sort(#"Tipo cambiado",{{"Revenue", Order.Descending}})
in
    #"Filas ordenadas";

shared Monthly = let
    Origen = Sales_clean,
    #"Inicio del mes insertado" = Table.AddColumn(Origen, "Inicio del mes", each Date.StartOfMonth([InvoiceDate]), type datetime),
    #"Columnas con nombre cambiado" = Table.RenameColumns(#"Inicio del mes insertado",{{"Inicio del mes", "Month"}}),
    #"Tipo cambiado" = Table.TransformColumnTypes(#"Columnas con nombre cambiado",{{"Month", type date}}),
    #"Filas filtradas" = Table.SelectRows(#"Tipo cambiado", each [Month] < #date(2011, 12, 1)),
    #"Filas agrupadas" = Table.Group(#"Filas filtradas", {"StockCode", "Month"}, {{"Units", each List.Sum([Quantity]), type nullable number}}),
    #"Filas ordenadas" = Table.Sort(#"Filas agrupadas",{{"Month", Order.Ascending}}),
    #"Columna dinamizada" = Table.Pivot(Table.TransformColumnTypes(#"Filas ordenadas", {{"Month", type text}}, "es-ES"), List.Distinct(Table.TransformColumnTypes(#"Filas ordenadas", {{"Month", type text}}, "es-ES")[Month]), "Month", "Units", List.Sum),
    #"Valor reemplazado" = Table.ReplaceValue(#"Columna dinamizada",null,0,Replacer.ReplaceValue,{"01/12/2010", "01/01/2011", "01/02/2011", "01/03/2011", "01/04/2011", "01/05/2011", "01/06/2011", "01/07/2011", "01/08/2011", "01/09/2011", "01/10/2011", "01/11/2011"})
in
    #"Valor reemplazado";