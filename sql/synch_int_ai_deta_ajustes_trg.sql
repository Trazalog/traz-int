create trigger synch_int_ai before
insert
    or
update
    on
    alm.deta_ajustes for each row execute procedure synch_deta_ajustes_trg();
