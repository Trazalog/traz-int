CREATE  TRIGGER tzl_synch_articulos_trg ON Empresa_Ejemplo.dbo.STA11
AFTER INSERT, UPDATE, DELETE
AS
	BEGIN
	    -- Trigger que toma datos especificos de la tabla STA11 de Articulos TANGO en caso de producirse un evento.
	    -- Checkeo si fue un INSERT, UPDATE o DELETE.
	    --
		declare @action char(1)
		declare @v_cod_medida char(4)
		declare @v_id_medida int
		SET @action = 
			(CASE WHEN EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED) -- UPDATE
                THEN 'U'
                WHEN EXISTS(SELECT * FROM INSERTED) -- INSERT
                THEN 'I'
                WHEN EXISTS(SELECT * FROM DELETED) -- DELETE
                THEN 'D'
                ELSE NULL -- No hago nada, puede haber sido un falso movimiento.
            END)
        -- tomo el codigo de unidad de medida a traducir en tools
        if @action = 'U'
		    -- Caso en el que fue un UPDATE
		    --
		    BEGIN
			    if(update(COD_ARTICU) or update(DESCRIPCIO) or  update(ID_MEDIDA_STOCK))
				        insert into dbo.novedades_clientes_queue (data_json)
						select '{"tabla":"articulos","barcode":"'+ cast( i.COD_ARTICU COLLATE SQL_Latin1_General_CP850_BIN as VARCHAR(15)) + '","descripcion": "' + ISNULL(i.DESCRIPCIO,'') + '", "unidad_medida": "' + M.COD_MEDIDA + '","id_articulo": "' + CONVERT(varchar(40),ISNULL(i.COD_ARTICU, 0))+ '","accion": "update"}' as data_json
						from INSERTED i
						,MEDIDA M
	        			WHERE M.ID_MEDIDA= i.ID_MEDIDA_STOCK
	        	else if (update(PERFIL)) -- si el perfil es I es un borrado logico
				        insert into dbo.novedades_clientes_queue (data_json)
						select '{"tabla":"articulos","barcode":"'+ cast( i.COD_ARTICU COLLATE SQL_Latin1_General_CP850_BIN as VARCHAR(15))  + '","descripcion": "' + ISNULL(i.DESCRIPCIO,'') + '", "unidad_medida": "' + M.COD_MEDIDA + '","id_articulo": "' + CONVERT(varchar(40),ISNULL(i.ID_STA11, 0))+ '","accion": "delete"}' as data_json
						from INSERTED i
						,MEDIDA M
	        			WHERE M.ID_MEDIDA= i.ID_MEDIDA_STOCK
	        			and i.PERFIL='I'
		    END
		 else if @action = 'I'
		 -- Caso en el que fue un INSERT
		    --
		    BEGIN
				        insert into dbo.novedades_clientes_queue (data_json)
						select '{"tabla":"articulos","barcode":"'+ cast( i.COD_ARTICU COLLATE SQL_Latin1_General_CP850_BIN as VARCHAR(15))  + '","descripcion": "' + ISNULL(i.DESCRIPCIO,'') + '", "unidad_medida": "' + M.COD_MEDIDA + '","id_articulo": "' + CONVERT(varchar(40),ISNULL(i.COD_ARTICU, 0))+ '","accion": "insert"}' as data_json
						from INSERTED i
						,MEDIDA M
	        			WHERE M.ID_MEDIDA= i.ID_MEDIDA_STOCK
	        END
		 else
		 -- Caso en el que fue un DELETE
		    --
		    BEGIN
				        insert into dbo.novedades_clientes_queue (data_json)
						select '{"tabla":"articulos","barcode":"'+ cast( i.COD_ARTICU COLLATE SQL_Latin1_General_CP850_BIN as VARCHAR(15))  + '","descripcion": "' + ISNULL(i.DESCRIPCIO,'') + '", "unidad_medida": "' + M.COD_MEDIDA + '","id_articulo": "' + CONVERT(varchar(40),ISNULL(i.COD_ARTICU, 0))+ '","accion": "delete"}' as data_json
						from INSERTED i
						,MEDIDA M
	        			WHERE M.ID_MEDIDA= i.ID_MEDIDA_STOCK
		    END
	END
;
