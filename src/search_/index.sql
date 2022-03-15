
-- search_.type has registered type
-- and also "pointers" to related types and functions
--
create table search_.type (
    id text not null primary key,

    table_t regclass,
    param_t regtype,
    match_it regtype,

    param_f regprocedure, -- param_f(table_t) to set param
    match_f regprocedure, -- match_f(param_t, match_it) to match
    jsonb_f regprocedure  -- jsonb_f(table_t) for result
);


-- search_.item is the base table to be inherited
--
create table search_.item (

    id text default md5(uuid_generate_v4()::text) primary key,

    type text references search_.type(id),

    param jsonb
);
