create trigger synch_int_ai after
insert
    on
    prd.lotes_hijos for each row execute procedure synch_lotes_hijos_trg()
