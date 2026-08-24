-- Category catalog with counts of published content only
create or replace view public.category_catalog as
select
  c.id, c.slug, c.name, c.description, c.sort_order,
  count(distinct x.id)::int as content_count
from public.categories c
left join public.content_categories cc on cc.category_id = c.id
left join public.contents x on x.id = cc.content_id and x.status = 'published'
where c.is_active = true
group by c.id, c.slug, c.name, c.description, c.sort_order;

grant select on public.category_catalog to anon, authenticated;
