create trigger sinch_int_ai before
insert
    or
update
    on
    alm.deta_movimientos_internos for each row execute procedure synch_deta_movimientos_internos_trg();
