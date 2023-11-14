CREATE OR REPLACE FUNCTION "int".synch_yudi_neumaticos_terminados_trg()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	BEGIN
declare 
		v_empr_id int;
		v_form_id int;
		vt_form_id int;
		v_valor varchar; 
		v_valor_num_serie varchar;
		v_valor_marca varchar;
		v_data_json varchar;
	
	BEGIN	
		/**
		 * syncroniza neumaticos terminados con Tango
		 * 
		 */
		RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg-  petr_id: % ', new.petr_id;

		if new.estado = 'estados_yudicaENTREGADO' and new.int_pedi_id is not null and new.int_pedi_id != '' then
			
		
			--obtengo el empr_id de yudica
			select e.empr_id 
			into strict v_empr_id 
			from core.empresas e 
			where e.descripcion = 'Yudica';
				
			RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg-  empr_id: % ', v_empr_id ;
		
			-- obtengo datos del formulario que se esta guardando en Cabina
			-- si no existe el form para la emresa
			select f.form_id 
			into strict v_form_id
			from frm.formularios f 
			where f.empr_id = v_empr_id
			and f.nombre = 'Preparación de la Banda' ;
		
			RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg- form_id: % ', v_form_id ;
		
			-- obtengo el codigo de banda utilizado en la reparación del neumático
			select t.valor --,t.descripcion 
			into strict v_valor
			from frm.instancias_formularios  i 
				,pro.pedidos_trabajo_forms ptf 
				,core.tablas t 
			where i.info_id = ptf.info_id 
			and ptf.petr_id = new.petr_id
			and i.form_id = v_form_id
			and t.tabl_id = i.valor
			and i."name" = 'tipo_banda'
			order by i.fec_alta desc 
			limit 1;
		
			RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg- banda: % ', v_valor ;
		
			-- obtengo marca de neumatico de banda utilizado en la reparación del neumático
			select t.valor 
			into strict v_valor_marca
			from frm.instancias_formularios i 
				,pro.pedidos_trabajo_forms ptf 
				,core.tablas t 
			where i.info_id = ptf.info_id 
			and ptf.petr_id = new.petr_id
			and i.form_id = v_form_id
			and t.tabl_id = i.valor
			and i."name" = 'marca' 
			order by i.fec_alta desc 
			limit 1;
			
			RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg- marca: % ', v_valor_marca ;
		
			-- obtengo datos del formulario que se esta guardando en la creacion del pedido de trabajo
			-- si no existe el form para la emresa
			select f.form_id 
			into strict vt_form_id
			from frm.formularios f 
			where f.empr_id = v_empr_id
			and f.nombre = 'Recepción Neumático' ;
		
			RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg- vt_form_id: % ', vt_form_id ;

			-- obtengo el numero de serie de banda utilizado en la reparación del neumático
			select i.valor 
			into strict v_valor_num_serie
			from frm.instancias_formularios  i
			where i.info_id = new.info_id 
			and i."name" = 'num_serie';
		
		RAISE INFO 'SYNCHYUDI - yudi_neumaticos_terminados_trg- num_serie: % ', v_valor_num_serie ;
		
		
		
			v_data_json = '{';
		--	v_data_json = v_data_json||'	"event":{';
			v_data_json = v_data_json||'			"tabla":"lineasPedido",';
			v_data_json = v_data_json||'			"accion":"'||TG_OP||'",';
			v_data_json = v_data_json||'			"num_pedido":"'||new.int_pedi_id||'",';
			v_data_json = v_data_json||'			"id_pedido_trabajo":"'||new.petr_id|| '",';--SACAR ESTE ESPACIO
			v_data_json = v_data_json||'			"banda":"'||v_valor||'",';
			v_data_json = v_data_json||'			"num_serie":"'||v_valor_num_serie||'",';
			v_data_json = v_data_json||'			"marca":"'||v_valor_marca||'",';
		--	v_data_json = v_data_json||'		}';
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
