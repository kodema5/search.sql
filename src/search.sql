\if :{?search_sql}
\else
\set search_sql true

-- a combined search?

-- how to create an abstract search?
-- supposed to have a set of products,
-- where each product has own attributes
-- one approach is to make a superset of columns
-- but is there another way?


\if :local
    drop schema if exists _search cascade;
\endif
create schema if not exists _search;
drop schema if exists search cascade;
create schema search;

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
        default md5(gen_random_uuid()::text)
        primary key,

    -- can be used for preliminary filtering in query
    --
    type text
        references _search.type(id),

    -- a param of which to search on (instead of the actual table)
    --
    param jsonb
);


-- abstract search.get_item queries matching items
--
create function search.get_item(jsonb)
    returns setof _search.item
    language sql
    stable
as $$
    select null::_search.item where false
$$;

-- abstract search.to_jsonb transforms an item to uniform type
--
create function search.to_jsonb(_search.item)
    returns jsonb
    language sql
as $$
    select null::jsonb where false
$$;

-- search.get returns aggregrates matching items
-- returning _search.item and select * will inline query
-- override this as needed
--
create function search.get (
    req jsonb
)
    returns setof jsonb
    language sql
    security definer
    stable
as $$
    select search.to_jsonb(t)
    from search.get_item(req) t
$$;

\ir search/replace_get_fs.sql
\ir search/set_type.sql
\ir search/unset_type.sql
\ir search/tests/mod.sql

\endif