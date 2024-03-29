create table PK.LZ_JOURNAL_INFO
(
    KUERZEL       char(10) primary key,
    RANK          integer,
    JOURNAL       text,
    PUBLISHER     text,
    FACTOR        float,
    ADJ_CITATIONS integer,
    N_ARTICLES    integer,
    N_CITATIONS   integer
);

call PK.gen_tracking_functions('LZ_JOURNAL_INFO');