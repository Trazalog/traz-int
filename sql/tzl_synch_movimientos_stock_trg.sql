CREATE  TRIGGER tzl_synch_movimientos_stock_trg ON Empresa_Ejemplo.dbo.STA20
AFTER INSERT 
AS
	BEGIN
	    -- Trigger que toma datos especificos de la tabla STA20 de Movimientos de Stock de TANGO en caso de producirse un evento.
	    -- Checkeo si fue un INSERT, UPDATE o DELETE.
	    --
		insert into dbo.novedades_clientes_queue (data_json)
		select concat('{"tabla":"movimientosStock","id_articulo": "' 
				       , i.COD_ARTICU
				       , '", "cantidad":"'
				       , CASE when i.TIPO_MOV = 'E' then CAST(i.CANTIDAD AS DECIMAL(10,2)) else CAST(i.CANTIDAD * -1 AS DECIMAL(10,2)) end
				       , '","id_deposito":"'
				       ,i.COD_DEPOSI
				       ,'","id_mov":"'
				       ,i.ID_STA20
					   ,'","accion": "insert"}' )as data_json
		from INSERTED i
		where i.TCOMP_IN_S <>'AR'

END
;
