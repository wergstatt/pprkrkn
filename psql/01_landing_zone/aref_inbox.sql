drop table PK.LZ_AREF_INBOX;
create table PK.LZ_AREF_INBOX
(
    AREF     text,
    TS_ENTRY timestamp default current_timestamp
);

call PK.gen_tracking_functions('LZ_AREF_INBOX');