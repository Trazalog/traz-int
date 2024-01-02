CREATE OR REPLACE FUNCTION "int".synch_deta_ajustes_trg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	declare 
	
		--v_depo_id_origen int4;
 		v_depo_id alm.alm_lotes.depo_id%type;
		v_depo_inte_id varchar;
		v_arti_id alm.alm_lotes.arti_id%type;
		v_arti_inte_id varchar;
		v_tipo_ajuste varchar;
		v_operacion varchar;
		v_data_json varchar;
	begin
		/**
		 * syncroniza registros insertados o updateados en deta ajustes* 
		 */
	RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  deaj_id: % ', new.deaj_id;
		
	--obtengo tipo de ajuste 
		select tipo_ajuste
		into strict v_tipo_ajuste 
		from alm.ajustes a 
		where a.ajus_id = new.ajus_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_tipo_ajuste: % ', v_tipo_ajuste;
	
	-- si el tipo de ajuste es tipos_ajuste_stockTango viene de tango, no tengo que procesarlo
	if(v_tipo_ajuste not like 'tipos_ajuste_stockTango') then 
	
	--obtengo el tipo de operacion ENTRADA/SALIDA o E/S
		select valor2
		into strict v_operacion 
		from core.tablas t 
		where t.tabl_id like v_tipo_ajuste;	
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_tipo_ajuste: % ', v_operacion;
	
	
	-- movimientos de salidas
	if v_operacion like 'SALIDA' then
	
	--obtengo el id de deposito asosiados al movimiento
		select depo_id, arti_id
		into strict v_depo_id, v_arti_id
		from alm.alm_lotes al 
		where al.lote_id  = new.lote_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_depo_id: % ', v_depo_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_arti_id: % ', v_arti_id;
	
	--obtengo el id de deposito del sistema integrado
		select inte_id
		into strict v_depo_inte_id
		from alm.alm_depositos ad 
		where ad.depo_id = v_depo_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_depo_inte_id: % ', v_depo_inte_id;
	

	--obtengo el id del articulo del sistema integrado
		select inte_id
		into strict v_arti_inte_id
		from alm.alm_articulos a 
		where a.arti_id = v_arti_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_arti_inte_id: % ', v_arti_inte_id;
	
	if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
	v_data_json = '{';
--			v_data_json = v_data_json||'	"event":{';
			v_data_json = v_data_json||'			"tabla":"movimientosStock",';
			v_data_json = v_data_json||'			"accion":"SALIDA",';
			v_data_json = v_data_json||'			"id_movimiento":"'||new.deaj_id::text||'",';
			v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
			v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad::text || '",';
			v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
			--v_data_json = v_data_json||'			"fec_movimiento":"'|| to_char(now(),'DD-MM-YYYY HH24:MI:SS')||'"';
	--		v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  data_json: % ', v_data_json;
		
				-- armo el data_json para ser procesado por el conector
			INSERT INTO int.jlmi_synch_queue 
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,new.empr_id);
	  		return new;
		else
			RAISE WARNING 'SYNCHINT - synch_deta_ajustes_trg -  error calculando deposito y articulo para integracion: %: %', v_depo_id,v_arti_id;
			return new;
		end if;
	else 
		return new;
	end if; --fin if salida
	
--movimiento de entrada
	if v_operacion like 'ENTRADA' then
	
	--obtengo el id de deposito asosiados al movimiento
		select depo_id, arti_id
		into strict v_depo_id, v_arti_id
		from alm.alm_lotes al 
		where al.lote_id  = new.lote_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_depo_id: % ', v_depo_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_arti_id: % ', v_arti_id;
	
	--obtengo el id de deposito del sistema integrado
		select inte_id
		into strict v_depo_inte_id
		from alm.alm_depositos ad 
		where ad.depo_id = v_depo_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_depo_inte_id: % ', v_depo_inte_id;
	

	--obtengo el id del articulo del sistema integrado
		select inte_id
		into strict v_arti_inte_id
		from alm.alm_articulos a 
		where a.arti_id = v_arti_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_arti_inte_id: % ', v_arti_inte_id;
	
	if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
	v_data_json = '{';
--			v_data_json = v_data_json||'	"event":{';
			v_data_json = v_data_json||'			"tabla":"movimientosStock",';
			v_data_json = v_data_json||'			"accion":"ENTRADA",';
			v_data_json = v_data_json||'			"id_movimiento":"'||new.deaj_id::text||'",';
			v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
			v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad::text || '",';
			v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
			--v_data_json = v_data_json||'			"fec_movimiento":"'|| to_char(now(),'DD-MM-YYYY HH24:MI:SS')||'"';
	--		v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  data_json: % ', v_data_json;
		
				-- armo el data_json para ser procesado por el conector
			INSERT INTO int.jlmi_synch_queue 
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,new.empr_id);
	  		return new;
		else
			RAISE WARNING 'SYNCHINT - synch_deta_ajustes_trg -  error calculando deposito y articulo para integracion: %: %', v_depo_id,v_arti_id;
			return new;
		end if;
	else
		return new;
	end if; --fin if entrada

--movimiento de E/S genera una entrada y una salida
	if v_operacion like 'E/S' then
	
	--obtengo el id de deposito asosiados al movimiento
		select depo_id, arti_id
		into strict v_depo_id, v_arti_id
		from alm.alm_lotes al 
		where al.lote_id  = new.lote_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_depo_id: % ', v_depo_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_arti_id: % ', v_arti_id;
	
	--obtengo el id de deposito del sistema integrado
		select inte_id
		into strict v_depo_inte_id
		from alm.alm_depositos ad 
		where ad.depo_id = v_depo_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_depo_inte_id: % ', v_depo_inte_id;
	

	--obtengo el id del articulo del sistema integrado
		select inte_id
		into strict v_arti_inte_id
		from alm.alm_articulos a 
		where a.arti_id = v_arti_id;
		RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  v_arti_inte_id: % ', v_arti_inte_id;
	
	-- si la cantidad es mayor a 0 es movimiento de entrada
	if new.cantidad > 0 then
	
		if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
			v_data_json = '{';
--				v_data_json = v_data_json||'	"event":{';
				v_data_json = v_data_json||'			"tabla":"movimientosStock",';
				v_data_json = v_data_json||'			"accion":"ENTRADA",';
				v_data_json = v_data_json||'			"id_movimiento":"'||new.deaj_id::text||'",';
				v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
				v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad::text || '",';
				v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
				--v_data_json = v_data_json||'			"fec_movimiento":"'|| to_char(now(),'DD-MM-YYYY HH24:MI:SS')||'"';
	--			v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  data_json: % ', v_data_json;
		
				-- armo el data_json para ser procesado por el conector
			INSERT INTO int.jlmi_synch_queue 
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,new.empr_id);
			return new;
		else
			RAISE WARNING 'SYNCHINT - synch_deta_ajustes_trg -  error calculando deposito y articulo para integracion: %: %', v_depo_id,v_arti_id;
			return new;
		end if;
	-- si la cant es menor a 0 es movimiento de salida
	else 
		if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
			v_data_json = '{';
--				v_data_json = v_data_json||'	"event":{';
				v_data_json = v_data_json||'			"tabla":"movimientosStock",';
				v_data_json = v_data_json||'			"accion":"SALIDA",';
				v_data_json = v_data_json||'			"id_movimiento":"'||new.deaj_id::text||'",';
				v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
				v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad::text || '",';
				v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
				--v_data_json = v_data_json||'			"fec_movimiento":"'|| to_char(now(),'DD-MM-YYYY HH24:MI:SS')||'"';
	--			v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHINT - synch_deta_ajustes_trg -  data_json: % ', v_data_json;
		
				-- armo el data_json para ser procesado por el conector
			INSERT INTO int.jlmi_synch_queue 
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,new.empr_id);
	  		return new;
		else
			RAISE WARNING 'SYNCHINT - synch_deta_ajustes_trg -  error calculando deposito y articulo para integracion: %: %', v_depo_id,v_arti_id;
			return new;
		end if;
	return new;
	end if; --fin if cantidad
	else 
	return new;
end if; --fin if 'E/S'
else
	return new;
end if;	--fin 'tipos_ajuste_stockTango'
END;
$function$
;
