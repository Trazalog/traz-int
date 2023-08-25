create trigger synch_int_ai after
insert
    on
    alm.alm_deta_entrega_materiales for each row execute procedure synch_deta_entrega_materiales_trg()
