CREATE OR REPLACE FUNCTION "int".traducir_valor_tabla_in(p_empr_id integer, p_tabla character varying, p_valor character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
	declare 
		v_traducido varchar;
	begin
		/* funciona utilizada cuando se desea integrar con otros sistemas 
		 * y se precisa traducción de las listas de valores
		 * en valor3 hay que guardar el codigo del sistema origen
		 */
		if p_empr_id is not null then
			select t.tabl_id 
			into strict v_traducido 
			from core.tablas t
			where t.tabla = p_empr_id||'-'||p_tabla 
			and t.valor3= p_valor
			and t.empr_id = p_empr_id;
		else
			select t.tabl_id 
			into strict v_traducido 
			from core.tablas t
			where t.tabla = p_tabla 
			and t.valor3= p_valor
			and t.empr_id is null;
		end if;
	
		return v_traducido;
	
	exception
		when others then 	
			return p_valor;
	END;
$function$
;

