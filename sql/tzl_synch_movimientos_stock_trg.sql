CREATE  TRIGGER tzl_synch_movimientos_stock_trg ON kolormax.dbo.STA20
AFTER INSERT 
AS
	BEGIN TRY
	    -- Trigger que toma datos especificos de la tabla STA20 de Movimientos de Stock de TANGO en caso de producirse un evento.
	    -- Checkeo si fue un INSERT, UPDATE o DELETE.
	    --
	    PRINT N'tzl_synch_movimientos_stock_trg - Procesando movimiento a sincronizar';
	    	
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

		PRINT N'tzl_synch_movimientos_stock_trg - Finalizando sincronización de movimientos';
		
	END TRY
	BEGIN CATCH

	 	PRINT N'tzl_synch_movimientos_stock_trg - Errors Catch:'+error_message();
		
		BEGIN TRY
			/* on any possible exception, a log record is generated on errors table*/
		 	INSERT INTO dbo.tzl_errors
				([TYPE], number, state, severity, line, procedure_name, message)
		    VALUES
			  ('loadProductCatalog',
			   ERROR_NUMBER(),
			   ERROR_STATE(),
			   ERROR_SEVERITY(),
			   ERROR_LINE(),
			   ERROR_PROCEDURE(),
			   ERROR_MESSAGE());
		END TRY
		BEGIN CATCH
			 	PRINT N'tzl_synch_movimientos_stock_trg - Errors inserting error in log table :'+error_message();
		END CATCH	
	END CATCH