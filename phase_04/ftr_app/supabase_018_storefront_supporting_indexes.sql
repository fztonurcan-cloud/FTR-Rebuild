create index if not exists storefront_samples_selected_by_idx
  on private.storefront_samples(selected_by);

create index if not exists storefront_sample_assets_asset_id_idx
  on private.storefront_sample_assets(asset_id);

create index if not exists storefront_sample_assets_selected_by_idx
  on private.storefront_sample_assets(selected_by);
