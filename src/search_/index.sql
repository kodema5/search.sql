
-- search_.type has registered type
-- and also "pointers" to related types and functions
--
create table search_.type (
    id text not null primary key,

    table_t regclass,     -- actual item table
    param_f regprocedure, -- param_f(table_t) -> param_t -> param jsonb

    param_t regtype,      -- param jsonb   -> param_t

    match_it regtype,     -- request jsonb -> match_it
    match_f regprocedure, -- match_f(param_t, match_it) to check match

    jsonb_f regprocedure  -- jsonb_f(table_t) -> jsonb
);

---------------------------------------------------
-- search_.item is the base table to be inherited |
---------------------------------------------------
-- search_.item
--      item-type-1
--      item-type-2
--      ...
--
create table search_.item (

    id text default md5(uuid_generate_v4()::text) primary key,

    type text references search_.type(id), -- which type

    param jsonb  -- to be cast to type.param_t
);
