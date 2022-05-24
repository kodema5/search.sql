

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


\ir replace_get_fs.sql

\ir set_type.sql

\ir unset_type.sql