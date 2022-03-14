-- sets the type
-- registers the various types and function pointers needed for type
-- ensures inheritance
-- attach trigger to populate param column
-- reset/updates the search.get functions
--
create procedure search.set_type (
    id_ text,

    data_sch text default '',
    code_sch text default '',

    table_t_ regclass default null,
    param_t_ regclass default null,
    match_it_ regclass default null,

    param_f_ regprocedure default null,
    match_f_ regprocedure default null,
    jsonb_f_ regprocedure default null
)
    language plpgsql
    security definer
as $$
declare
    a search_.type;
begin
    select t into a
    from search_.type t
    where t.id = id_;

    a.id = id_;
    a.table_t = coalesce(table_t_, a.table_t, (data_sch || '.' || a.id )::regclass);
    a.param_t = coalesce(param_t_, a.param_t, (code_sch || '.param_t')::regclass);
    a.match_it = coalesce(match_it_, a.match_it, (code_sch || '.match__it')::regclass);
    a.param_f = coalesce(param_f_, a.param_f, (code_sch || '.get_param(' || a.table_t || ')')::regprocedure);
    a.match_f = coalesce(match_f_, a.match_f, (code_sch || '.match(' || a.param_t ||',' || a.match_it|| ')')::regprocedure);
    a.jsonb_f = coalesce(jsonb_f_, a.jsonb_f, (code_sch || '.to_jsonb(' || a.table_t || ')')::regprocedure);

    insert into search_.type values (a.*)
    on conflict (id) do update set
        table_t = a.table_t,
        param_t = a.param_t,
        match_it = a.match_it,
        param_f = a.param_f,
        match_f = a.match_f,
        jsonb_f = a.jsonb_f
    returning *
    into a;

    call search.set_type_inheritance(a);
    call search.set_type_param_trigger(a);
    call search.replace_get_fs();
end;
$$;

-- ensure type inherits search_.item
--
create procedure search.set_type_inheritance (
    t search_.type
)
    language plpgsql
    security definer
as $$
begin
    if not exists (
        select 1
        from pg_inherits
        where inhrelid = t.table_t
    )
    then
        execute format('
            alter table %s inherit search_.item
        ', t.table_t);
    end if;
end;
$$;

-- trigger to set the param column
--
create function search.search_set_type_param_trigger()
    returns trigger
    language plpgsql
    security definer
as $$
declare
    t search_.type;
begin
    select ts.*
    into t
    from search_.type ts
    where id = new.type;


    if t.id is not null
    then
        execute format('select to_jsonb(%s($1))', t.param_f::regproc)
        using new
        into new.param;
    end if;

    return coalesce(new, old);
end;
$$;


-- creates trigger on table
--
create procedure search.set_type_param_trigger (
    t search_.type
)
    language plpgsql
    security definer
as $$
begin
    if not exists (
        select 1
        from pg_trigger
        where tgrelid = t.table_t
            and tgname = 'search_set_type_param_trigger'
    ) then
        execute format('
            create trigger search_set_type_param_trigger
            before insert or update
            on %s
            for each row
            execute procedure search.search_set_type_param_trigger()
        ', t.table_t);
    end if;
end;
$$;

