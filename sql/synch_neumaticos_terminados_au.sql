create trigger synch_neumaticos_terminados_au after
update
    on
    pro.pedidos_trabajo for each row execute procedure synch_yudi_neumaticos_terminados_trg()
