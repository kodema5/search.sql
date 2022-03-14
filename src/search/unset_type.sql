-- unsets a type
-- removes from inheritance
-- removes the trigger
-- resets/updates the search.get functions
-- removes from table
--
create procedure search.unset_type (
    id_ text
)
    language plpgsql
    security definer
as $$
declare
    t search_.type;
begin

    select ts.*
    into t
    from search_.type ts
    where id = id_;

    call search.unset_type_inheritance(t);
    call search.unset_type_param_trigger(t);
    call search.replace_get_fs();

    delete from search_.type
    where id = id_;
end;
$$;


create procedure search.unset_type_inheritance (
    t search_.type
)
    language plpgsql
    security definer
as $$
begin
    if exists (
        select 1
        from pg_inherits
        where inhrelid = t.table_t
    )
    then
        execute format('
            alter table %s no inherit search_.item
        ', t.table_t);
    end if;
end;
$$;


create procedure search.unset_type_param_trigger (
    t search_.type
)
    language plpgsql
    security definer
as $$
begin
    if exists (
        select 1
        from pg_trigger
        where tgrelid = t.table_t
            and tgname = 'search_set_type_param_trigger'
    ) then
        execute format('
            drop trigger if exists search_set_type_param_trigger on %s
        ', t.table_t);
    end if;
end;
$$;
