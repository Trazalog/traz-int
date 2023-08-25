CREATE OR REPLACE FUNCTION "int".synch_yudi_neumaticos_terminados_trg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	BEGIN
declare 
		v_empr_id int;
		v_form_id int;
		v_valor varchar; 
		v_data_json varchar;
	
	BEGIN	
		/**
		 * syncroniza neumaticos terminados con Tango
		 * 
		 */
		RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg-  petr_id: % ', new.petr_id;

		if new.estado = 'estados_yudicaENTREGADO' then
			
			--obtengo el empr_id de yudica
			select e.empr_id 
			into strict v_empr_id 
			from core.empresas e 
			where e.descripcion = 'Yudica';
				
			-- obtengo datos del formulario que se esta guardando en Cabina
			-- si no existe el form para la emresa
			select f.form_id 
			into strict v_form_id
			from frm.formularios f 
			where f.empr_id = v_empr_id
			and f.nombre = 'Preparación de la Banda' ;
		
			-- obtengo el codigo de banda utilizado en la reparación del neumático
			select i.valor 
			into strict v_valor
			from frm.instancias_formularios  i 
				,pro.pedidos_trabajo_forms ptf 
			where i.info_id = ptf.info_id 
			and ptf.petr_id = new.petr_id
			and i.form_id = v_form_id
			and i."name" = 'tipo_banda' ;
		
			v_data_json = '{';
			v_data_json = v_data_json||'	"event":{';
			v_data_json = v_data_json||'			"tabla":"lineasPedido",';
			v_data_json = v_data_json||'			"accion":"'||TG_OP||'",';
			v_data_json = v_data_json||'			"num_pedido":"'||new.int_pedi_id||'",';
			v_data_json = v_data_json||'			"id_pedido_trabajo":"'||new.petr_id|| '",';--SACAR ESTE ESPACIO
			v_data_json = v_data_json||'			"banda":"'||v_valor||'",';		
			v_data_json = v_data_json||'		}';
			v_data_json = v_data_json||'	}';
	
			RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg-  data_json: % ', v_data_json;

			-- armo el data_json para ser procesado por el conector
			INSERT INTO int.yudi_synch_queue
			(data_json, fec_alta, fec_realizado, procesado,empr_id)
			VALUES(v_data_json,now(),now(),0,new.empr_id);

		end if;		
	  	return new;
	  
	  
	exception
		when no_data_found then
			RAISE WARNING 'SYNCHYUDI - yudi_neumaticos_terminados_trg-  no data found: %: %', sqlstate,sqlerrm;
			return new;
		
		when others then
			RAISE WARNING 'SYNCHYUDI - yudi_neumaticos_terminados_trg-  error extremo: %: %', sqlstate,sqlerrm;
			return new;
	end;

	END;
$function$
;

