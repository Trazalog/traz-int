CREATE OR REPLACE FUNCTION "int".synch_deta_entrega_materiales_trg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	declare 
	
		v_accion varchar;
		v_depo_inte_id varchar;
		v_arti_inte_id varchar;
		v_data_json varchar;
	
	BEGIN	
		/**
		 * syncroniza registros insertados o updateados en deta entrega materiales
		 * 
		 */
		RAISE INFO 'SYNCHINT - deta_entrega_materiales_trg -  deen_id: % ', new.deen_id;

		
		--obtengo el id de deposito del sistema integrado
		select inte_id
		into strict v_depo_inte_id
		from alm.alm_depositos ad 
		where ad.depo_id = new.depo_id;
		RAISE INFO 'SYNCHINT - deta_entrega_materiales_trg -  v_depo_inte_id: % ', v_depo_inte_id;

		--obtengo el id de deposito del sistema integrado
		select inte_id
		into strict v_arti_inte_id
		from alm.alm_articulos a 
		where a.arti_id = new.arti_id;
		RAISE INFO 'SYNCHINT - deta_entrega_materiales_trg -  v_arti_inte_id: % ', v_arti_inte_id;

		if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
			v_data_json = '{';
--			v_data_json = v_data_json||'	"event":{';
			v_data_json = v_data_json||'			"tabla":"movimientosStock",';
			v_data_json = v_data_json||'			"accion":"SALIDA",';
			v_data_json = v_data_json||'			"id_movimiento":"'||new.deen_id::text||'",';
			v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
			v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad::text || '",';
			v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
			--v_data_json = v_data_json||'			"fec_movimiento":"'|| to_char(now(),'DD-MM-YYYY HH24:MI:SS')||'"';
	--		v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHINT - deta_entrega_materiales_trg -  data_json: % ', v_data_json;

			-- armo el data_json para ser procesado por el conector
			INSERT INTO int.jlmi_synch_queue 
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,new.empr_id);
	  		return new;
		else
			RAISE WARNING 'SYNCHINT - deta_entrega_materiales_trg -  error calculando deposito y articulo para integracion: %: %', new.depo_id,new.arti_id;
			return new;
		end if;		
	exception
		when others then
			RAISE WARNING 'SYNCHINT - deta_entrega_materiales_trg -  error extremo: %: %', sqlstate,sqlerrm;
			return new;
	end;

$function$
;

