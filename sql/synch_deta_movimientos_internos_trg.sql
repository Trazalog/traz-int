CREATE OR REPLACE FUNCTION "int".synch_deta_movimientos_internos_trg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
 declare
		--v_depo_id_origen int4;
 		v_depo_id_origen int;
 		v_depo_id_destino int;
		v_depo_inte_id varchar;
		v_arti_inte_id varchar;
		v_data_json varchar;
		v_empr_id int;
	begin
		/**
		 * syncroniza registros insertados o updateados en deta movimientos internos * 
		 */
	RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  demi_id: % ', new.demi_id;

/*	CASO INSERT
 * si el lote_id_destino es null tengo que hacer una salida 
 * de articulo del deposito lote_id_origen
 * 
 * */
if new.lote_id_destino is null then

	--obtengo el id de deposito asosiados al movimiento
		select depo_id_origen, empr_id, v_depo_id_destino
		into strict v_depo_id_origen, v_empr_id
		from alm.movimientos_internos mi 
		where mi.moin_id  = new.moin_id;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_depo_id_origen: % ', v_depo_id_origen;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_empr_id: % ', v_empr_id;
	

	--obtengo el id del articulo del sistema integrado
		select inte_id
		into strict v_arti_inte_id
		from alm.alm_articulos a 
		where a.arti_id = new.arti_id;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_arti_inte_id: % ', v_arti_inte_id;



--obtengo el id de deposito del sistema integrado
		select inte_id
		into strict v_depo_inte_id
		from alm.alm_depositos ad 
		where ad.depo_id = v_depo_id_origen;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_depo_inte_id: % ', v_depo_inte_id;
	
	if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
			v_data_json = '{';
--			v_data_json = v_data_json||'	"event":{';
			v_data_json = v_data_json||'			"tabla":"movimientosStock",';
			v_data_json = v_data_json||'			"accion":"SALIDA",';
			v_data_json = v_data_json||'			"id_movimiento":"'||new.demi_id::text||'",';
			v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
			v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad_cargada::text || '",';
			v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
			--v_data_json = v_data_json||'			"fec_movimiento":"'|| to_char(now(),'DD-MM-YYYY HH24:MI:SS')||'"';
	--		v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  data_json: % ', v_data_json;
		
				-- armo el data_json para ser procesado por el conector
			INSERT INTO int.jlmi_synch_queue 
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,v_empr_id);
	  		--return new;
		else
			RAISE WARNING 'SYNCHINT - synch_deta_movimientos_internos_trg -  error calculando deposito y articulo para integracion: %: %', v_depo_id_origen,new.arti_id;
			return new;
		end if;		
	else 
/* CASO UPDATE
 * si el lote_id_destino no es null, se hizo la recepcion del pedido 
 * y hago una entrada al nuevo deposito lote_id_destino
 * */	
	--obtengo el id de deposito asosiados al movimiento
		select depo_id_destino, empr_id
		into strict v_depo_id_destino, v_empr_id
		from alm.movimientos_internos mi 
		where mi.moin_id  = new.moin_id;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_depo_id_destino: % ', v_depo_id_destino;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_empr_id: % ', v_empr_id;
	

	--obtengo el id del articulo del sistema integrado
		select inte_id
		into strict v_arti_inte_id
		from alm.alm_articulos a 
		where a.arti_id = new.arti_id;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_arti_inte_id: % ', v_arti_inte_id;



	--obtengo el id de deposito del sistema integrado
		select inte_id
		into strict v_depo_inte_id
		from alm.alm_depositos ad 
		where ad.depo_id = v_depo_id_destino;
		RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  v_depo_inte_id: % ', v_depo_inte_id;
	
	if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
			v_data_json = '{';
--			v_data_json = v_data_json||'	"event":{';
			v_data_json = v_data_json||'			"tabla":"movimientosStock",';
			v_data_json = v_data_json||'			"accion":"ENTRADA",';
			v_data_json = v_data_json||'			"id_movimiento":"'||new.demi_id::text||'",';
			v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
			v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad_recibida::text || '",';
			v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
			--v_data_json = v_data_json||'			"fec_movimiento":"'|| to_char(now(),'DD-MM-YYYY HH24:MI:SS')||'"';
	--		v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHINT - synch_deta_movimientos_internos_trg -  data_json: % ', v_data_json;
		
				-- armo el data_json para ser procesado por el conector
			INSERT INTO int.jlmi_synch_queue 
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,v_empr_id);
	  		--return new;
		else
			RAISE WARNING 'SYNCHINT - synch_deta_movimientos_internos_trg -  error calculando deposito y articulo para integracion: %: %', v_depo_id_origen,new.arti_id;
			return new;
		end if;		
	end if;
	return new;
	exception
		when others then
			RAISE WARNING 'SYNCHINT - synch_deta_movimientos_internos_trg -  error extremo: %: %', sqlstate,sqlerrm;
			return new;
		
	END;

$function$
;
