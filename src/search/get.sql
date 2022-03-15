
-- abstract search.get_item queries matching items
--
create function search.get_item(jsonb)
    returns setof search_.item
    language sql
    stable
as $$
    select null::search_.item where false
$$;

-- abstract search.to_jsonb transforms an item to uniform type
--
create function search.to_jsonb(search_.item)
    returns jsonb
    language sql
as $$
    select null::jsonb where false
$$;

-- search.get returns aggregrates matching items
-- returning search_.item and select * will inline query
-- override this as needed
--
create function search.get (
    req jsonb
)
    -- returns setof search_.item
    returns setof jsonb
    language sql
    security definer
    stable
as $$
    -- select *
    select search.to_jsonb(t)
    from search.get_item(req) t
$$;


-- search.get_item and search.to_jsonb are replaced base on
-- search_.type as below:
--
create procedure search.replace_get_fs ()
    language plpgsql
as $$
declare
    t text;
begin
    -- for all-types:

    -- update search.get_item(req)
    -- it uses match_f(param_t, match_it) to search for items
    execute format('
        create or replace function search.get_item (
            req jsonb
        )
            returns setof search_.item
            language sql
            stable
        as $fn$
            select *
            from search_.item t
            where (
                req->>''types'' is null
                or t.type = any (array(select jsonb_array_elements_text(req->''types'')))
            )
            and (%s)
        $fn$;
    ',(
        select array_to_string(array_agg(format('
            (
                t.type=%L
                and %s(
                    jsonb_populate_record(null::%s, t.param),
                    jsonb_populate_record(null::%s, req)
                )
            )', t.id, t.match_f::regproc, t.param_t, t.match_it)),
            ' OR ')
        from search_.type t
    ));

    -- update search.to_jsonb(item)
    -- to transform output uniformly as a jsonb
    --
    execute format('
        create or replace function search.to_jsonb (
            i search_.item
        )
            returns jsonb
            language sql
            stable
        as $fn$
            select case
            %s
            else null
            end;
        $fn$;
    ', (
        select array_to_string(array_agg(format('
            when i.type = %L
            then (
                select %s(a) from %s a where a.id=i.id
            )
        ', t.id, t.jsonb_f::regproc, t.table_t)),
        '')
        from search_.type t
    ));

end;
$$;

