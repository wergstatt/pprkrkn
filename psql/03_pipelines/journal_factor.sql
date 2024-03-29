-- TYPE: TIME-SERIES

create table PK.CT_JOURNAL_FACTOR
(
    PUB      char(3),
    JOUR     char(6),
    FACTOR   float,
    TS_ENTRY timestamp default current_timestamp,
    foreign key (PUB, JOUR) references PK.IDX_JID (PUB, JOUR)
);

call pk.gen_tracking_functions('CT_JOURNAL_FACTOR');

create view PK.VIEW_SHUTTLE_JOURNAL_FACTOR as
select
    left(KUERZEL, 3)  as PUB,
    right(KUERZEL, 6) as JOUR,
    FACTOR,
    now()             as TS_ENTRY
    from PK.LZ_JOURNAL_INFO;

create view PK.VIEW_NEWBIES_JOURNAL_FACTOR as
select *
    from PK.VIEW_SHUTTLE_JOURNAL_FACTOR
    where not (PUB, JOUR, FACTOR) in (
        select PUB, JOUR, FACTOR
            from PK.CT_JOURNAL_FACTOR
    );

create view PK.VIEW_OLDIES_JOURNAL_FACTOR as
select
    CT.*,
    NEWB.TS_ENTRY as TS_ARCH
    from PK.CT_JOURNAL_FACTOR                     as CT
        inner join PK.VIEW_NEWBIES_JOURNAL_FACTOR as NEWB
                       on (CT.PUB, CT.JOUR) = (NEWB.PUB, NEWB.JOUR)
union all
select *, now()
    from PK.CT_JOURNAL_RANK
    where not (PUB, JOUR) in (
        select PUB, JOUR
            from PK.VIEW_SHUTTLE_JOURNAL_RANK )
;

create table PK.ARCH_JOURNAL_FACTOR as table PK.VIEW_OLDIES_JOURNAL_FACTOR with no data;

call pk.gen_tracking_functions('ARCH_JOURNAL_FACTOR');

create function PK.ETL_JOURNAL_FACTOR()
    returns trigger
as
$$
begin
    -- Send entries that will be updated (newbies) to the archive.
    insert into PK.ARCH_JOURNAL_FACTOR
    select *
        from PK.VIEW_OLDIES_JOURNAL_FACTOR;

    -- delete newbies.
    delete
        from PK.CT_JOURNAL_FACTOR
        where (PUB, JOUR) in (
            select PUB, JOUR
                from PK.VIEW_OLDIES_JOURNAL_FACTOR
        );

    -- insert newbies.
    insert into PK.CT_JOURNAL_FACTOR
    select *
        from PK.VIEW_NEWBIES_JOURNAL_FACTOR;

    return null;
end;
$$
    language plpgsql;

create trigger TRIG_1_ETL_JOURNAL_FACTOR
    after insert
    on PK.LZ_JOURNAL_INFO
    for each statement
execute procedure PK.ETL_JOURNAL_FACTOR();
