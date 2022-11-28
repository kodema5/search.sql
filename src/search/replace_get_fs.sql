\if :{?search_replace_get_fs_sql}
\else
\set search_replace_get_fs_sql true


-- search.get_item and search.to_jsonb are replaced base on
-- _search.type as below:
--
create procedure search.replace_get_fs ()
    language plpgsql
as $$
declare
    t text;
begin
    -- update search.get_item(req)
    -- it builds a function for
    -- select * from _search.item
    -- where (
        -- (type=a_type and match_f(param param_t, req match_it))
        -- or
        -- (type=b_type and match_f(param param_t, req match_it))
        -- ...
    -- )
    execute format('
        create or replace function search.get_item (
            req jsonb
        )
            returns setof _search.item
            language sql
            stable
        as $fn$
            select *
            from _search.item t
            where (
                req->>''types'' is null
                or t.type = any (array(select jsonb_array_elements_text(req->''types'')))
            )
            and (%s)
        $fn$;
    ',(
        -- (type=a_type and match_f(param param_t, req match_it))
        -- or
        -- (type=b_type and match_f(param param_t, req match_it))
        -- ...
        select array_to_string(array_agg(format('
            (
                t.type=%L
                and %s(
                    jsonb_populate_record(null::%s, t.param),
                    jsonb_populate_record(null::%s, req)
                )
            )', t.id, t.match_f::regprocedure::regproc, t.param_t, t.match_it)),
            ' OR ')
        from _search.type t
    ));


    -- update search.to_jsonb(item) that transforms uniformly as jsonb
    -- it builds a select-case for each type
    --      when type = a_type then (select jsonb_f(a) from table_t where id
    --      when type = b_type then (select jsonb_f(a) from table_t where id
    --      ....
    execute format('
        create or replace function search.to_jsonb (
            i _search.item
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
        ', t.id, t.jsonb_f::regprocedure::regproc, t.table_t)),
        '')
        from _search.type t
    ));

end;
$$;

\endif
