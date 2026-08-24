#!/usr/bin/env python3
from pathlib import Path
import json, sys
root=Path(__file__).resolve().parents[1]
p12=root/'supabase_012_phase47_premium_redaction.sql'
p13=root/'supabase_013_phase47_rls_invoker_content_detail.sql'
repo=root/'lib/data/repositories/supabase_ftr_repository.dart'
errors=[]
texts={}
for p in (p12,p13):
    if not p.exists(): errors.append(f'missing:{p.name}')
    else: texts[p.name]=p.read_text(encoding='utf-8').lower()
if p12.name in texts:
    s=texts[p12.name]
    required={
      'body_rls':'create policy content_bodies_read_entitled' in s,
      'asset_rls':'create policy content_assets_read_entitled' in s,
      'body_redaction':'case when t.has_access then b.body_html else null end' in s,
      'asset_redaction':"and (t.has_access or a.access_scope = 'preview')" in s,
      'published_only':"and c.status = 'published'" in s,
    }
    errors += [k for k,v in required.items() if not v]
if p13.name in texts:
    s=texts[p13.name]
    required={
      'security_invoker':'security invoker' in s,
      'empty_search_path':"set search_path = ''" in s,
      'body_column_grant':'grant select (content_id, body_html)' in s,
      'asset_column_grant':'grant select (' in s and 'access_scope' in s and 'storage_path' in s,
      'published_category_policy':'create policy content_categories_read_published' in s,
      'rpc_execute_grant':'grant execute on function public.get_content_detail(uuid) to anon, authenticated' in s,
    }
    errors += [k for k,v in required.items() if not v]
r=repo.read_text(encoding='utf-8') if repo.exists() else ''
if "rpc('get_content_detail'" not in r: errors.append('repository_not_using_rpc')
result={'ok':not errors,'passed_checks':12-len(errors),'expected_checks':12,'errors':errors}
print(json.dumps(result,ensure_ascii=False,indent=2))
sys.exit(0 if not errors else 2)
