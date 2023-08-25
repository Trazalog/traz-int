CREATE TRIGGER tzl_synch_clientes_trg ON Empresa_Ejemplo.dbo.GVA14
AFTER INSERT, UPDATE, DELETE
AS
	BEGIN
	    -- Trigger que toma datos especificos de la tabla GVA14 de clientes TANGO en caso de producirse un evento.
	    -- Checkeo si fue un INSERT, UPDATE o DELETE.
	    --
		DECLARE @action as char(1);
		SET @action = 
			(CASE WHEN EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED) -- UPDATE
                THEN 'U'
                WHEN EXISTS(SELECT * FROM INSERTED) -- INSERT
                THEN 'I'
                WHEN EXISTS(SELECT * FROM DELETED) -- DELETE
                THEN 'D'
                ELSE NULL -- No hago nada, puede haber sido un falso movimiento.
            END)
        if @action = 'U'
		    -- Caso en el que fue un UPDATE
		    --
		    BEGIN
			    if(update(RAZON_SOCI) or update(DOMICILIO) or update(DIR_COM) or update(ID_GVA14))
				        insert into dbo.novedades_clientes_queue (data_json)
						select '{"tabla":"clientes","razon_social": "' + ISNULL(RAZON_SOCI,'') + '", "domicilio": "' + ISNULL(DOMICILIO,'') + '","dir_comercial": "' + ISNULL(DIR_COM,'') + '","id_cliente": "' + CONVERT(varchar(12),ISNULL(ID_GVA14, 0)) + '","accion": "update"}' as data_json
						from INSERTED i
		    END
		 else if @action = 'I'
		 -- Caso en el que fue un INSERT
		    --
		    BEGIN
		        insert into dbo.novedades_clientes_queue (data_json)
				select '{"tabla":"clientes","razon_social": "' + ISNULL(RAZON_SOCI,'') + '", "domicilio": "' + ISNULL(DOMICILIO,'') + '","dir_comercial": "' + ISNULL(DIR_COM,'') + '","id_cliente": "' + CONVERT(varchar(12),ISNULL(ID_GVA14, 0)) + '","accion": "insert"}' as data_json
				from INSERTED i
		    END
		 else
		 -- Caso en el que fue un DELETE
		    --
		    BEGIN
		        insert into dbo.novedades_clientes_queue (data_json)
				select '{"tabla":"clientes","razon_social": "' + ISNULL(RAZON_SOCI,'') + '", "domicilio": "' + ISNULL(DOMICILIO,'') + '","dir_comercial": "' + ISNULL(DIR_COM,'') + '","id_cliente": "' + CONVERT(varchar(12),ISNULL(ID_GVA14, 0)) + '","accion": "delete"}' as data_json
				from DELETED i
		    END
	END
;