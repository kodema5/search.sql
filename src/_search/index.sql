
-- search_.type as types and "function-pointers"
--
create table if not exists _search.type (
    id text not null primary key,

    table_t regclass,     -- actual item table

    -- to generate _search.item param jsonb column
    -- param_t can be a sub-set of table_t columns
    --
    param_f regprocedure,
    param_t regtype,

    -- search request payload (a jsonb) will be cast to match_it
    -- make match_f (param_t, match_it) as immutable for possible inlining
    --
    match_it regtype,
    match_f regprocedure,

    -- jsonb_f(table_t) is to transform table_t into jsonb
    -- a required step for uniform output
    --
    jsonb_f regprocedure  -- jsonb_f(table_t) -> jsonb
);



-- _search.item is a parent table to be inherited on
-- it contains param to be searched on
--
-- _search.item
--      item-type-1
--      item-type-2
--      ...
--
create table if not exists _search.item (

    id text
        default md5(uuid_generate_v4()::text)
        primary key,

    -- can be used for preliminary filtering in query
    --
    type text
        references _search.type(id),

    -- a param of which to search on (instead of the actual table)
    --
    param jsonb
);
