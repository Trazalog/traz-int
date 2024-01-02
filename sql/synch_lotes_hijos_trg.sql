CREATE OR REPLACE FUNCTION "int".synch_lotes_hijos_trg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	declare 
	
		v_accion varchar;
		v_depo_inte_id varchar;
		v_arti_inte_id varchar;
		v_data_json varchar;
		v_depo_id alm.alm_depositos.depo_id%type;
		v_arti_id alm.alm_articulos.arti_id%type;
	
	
	BEGIN	
		/**
		 * syncroniza registros insertados o updateados en lotes hijos 
		 * si no tiene batch_id se ignora porque no viene desde lotes hijos sino de movimientos internos
		 */
		if new.batch_id is not null then
		
		begin
			
			RAISE INFO 'SYNCHINT - synch_lotes_hijos_trg -  batch: % ', new.batch_id;
		
			-- calculo datos del alm_lote asociado al batch_id
			select al.arti_id , al.depo_id 
			into strict v_arti_id, v_depo_id
			from alm.alm_lotes al 
			where al.batch_id = new.batch_id;
		 	
			RAISE INFO 'SYNCHINT - synch_lotes_hijos_trg -  v_arti_id: % ', v_arti_id;
			RAISE INFO 'SYNCHINT - synch_lotes_hijos_trg -  v_depo_id: % ', v_depo_id;
		
			--obtengo el id de deposito del sistema integrado
			select inte_id
			into strict v_depo_inte_id
			from alm.alm_depositos ad 
			where ad.depo_id = v_depo_id;
			RAISE INFO 'SYNCHINT - synch_lotes_hijos_trg -  v_depo_inte_id: % ', v_depo_inte_id;
	
			--obtengo el id de deposito del sistema integrado
			select inte_id
			into strict v_arti_inte_id
			from alm.alm_articulos a 
			where a.arti_id = v_arti_id;
			RAISE INFO 'SYNCHINT - synch_lotes_hijos_trg -  v_arti_inte_id: % ', v_arti_inte_id;
	
			if v_depo_inte_id is not null and v_depo_inte_id !='' and v_arti_inte_id is not null and v_arti_inte_id!='' then
				v_data_json = '{';
				v_data_json = v_data_json||'			"tabla":"movimientosStock",';
				v_data_json = v_data_json||'			"accion":"ENTRADA",';
				v_data_json = v_data_json||'			"id_movimiento":"'||new.batch_id::text||'",';
				v_data_json = v_data_json||'			"cod_articulo":"'||v_arti_inte_id||'",';
				v_data_json = v_data_json||'			"cantidad":"'|| new.cantidad::text || '",';
				v_data_json = v_data_json||'			"cod_deposito":"'||v_depo_inte_id||'",';
				v_data_json = v_data_json||'	}';
		
				RAISE INFO 'SYNCHINT - synch_lotes_hijos_trg -  data_json: % ', v_data_json;
	
				-- armo el data_json para ser procesado por el conector
				INSERT INTO int.jlmi_synch_queue 
				(data_json, fec_alta, fec_realizado, procesado,empr_id)
				VALUES(v_data_json,now(),now(),0,new.empr_id);
		  		return new;
			else
				RAISE WARNING 'SYNCHINT - synch_lotes_hijos_trg -  error calculando deposito y articulo para integracion: %: %', v_depo_id,v_arti_id;
				return new;
			end if;	

	exception
		when others then
			RAISE WARNING 'SYNCHINT - synch_lotes_hijos_trg -  error extremo: %: %', sqlstate,sqlerrm;
			return new;
	end;
	else 
		return new;
	end if;

exception
		when others then
			RAISE INFO 'SYNCHINT - synch_lotes_hijos_trg - lotes sin batch_id';
			return new;

	end;

$function$
;
