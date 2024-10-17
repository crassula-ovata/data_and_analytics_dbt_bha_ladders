with 
dm_table_data_location as (
    select 
    replace(site_code, '_', '') as site_code_compare,
    * from {{ source('dm_table_data', 'LOCATION') }} where site_code is not null
),
-- BR: these clinics/providers are edge case clinics that do not meet the expectation of legacy and bhe clinics having different id's. 
hades_table_exclude_bhe_in_legacy as (
    select * from 
         {{ source('hades_table_data', 'VWS_LADDERS_MAPPED_ACTIVE_LICENSES') }}
    where upper(account_id) not in 
        ( 
        '0014M00002QMJBGQAP',  --Young People in Recovery
        '0014M00002QMJ2CQAX', -- The Apprentice of Peace Youth Organization dba Trailhead Institute 
        '0014M00002QMIRYQA5', -- Advocates for Recovery Colorado
        '0014M00002QMI2YQAH', -- Built To Recover 
        '0014M00002QMKX0QAP' --Face It TOGETHER 
        )
)  
,hades_table_data_mapped_active_licenses_provider as (
      select 
        --replace(dm.external_id_format(legacy_parent_account_id), '_', '') || '-' || replace(dm.external_id_format(legacy_account_id), '_', '') as legacy_clinic_external_id,
        --dm.external_id_format(parent_account_id) || '-' || dm.external_id_format(account_id) as new_clinic_external_id,
        replace(dm.external_id_format(legacy_parent_account_id), '_', '') as legacy_provider_external_id,
        dm.external_id_format(parent_account_id) as new_provider_external_id,
        * from hades_table_exclude_bhe_in_legacy -- {{ source('hades_table_data', 'VWS_LADDERS_MAPPED_ACTIVE_LICENSES') }}
      where legacy_parent_account_id is not null and parent_account_id is not null
)
,legacy_records_in_bhe_provider as (
    select * from hades_table_data_mapped_active_licenses_provider where parent_account_id=legacy_parent_account_id
)
,hades_table_data_mapped_active_licenses_clinic as (
      select 
        replace(dm.external_id_format(legacy_parent_account_id), '_', '') || '-' || replace(dm.external_id_format(legacy_account_id), '_', '') as legacy_clinic_external_id,
        dm.external_id_format(parent_account_id) || '-' || dm.external_id_format(account_id) as new_clinic_external_id,
        replace(dm.external_id_format(legacy_parent_account_id), '_', '') as legacy_provider_external_id,
        dm.external_id_format(parent_account_id) as new_provider_external_id,
        * from hades_table_exclude_bhe_in_legacy -- {{ source('hades_table_data', 'VWS_LADDERS_MAPPED_ACTIVE_LICENSES') }}
      where legacy_parent_account_id is not null and legacy_account_id is not null
      and parent_account_id is not null and account_id is not null
)
,legacy_records_in_bhe_clinic as (
    select * from hades_table_data_mapped_active_licenses_clinic where parent_account_id=legacy_parent_account_id and account_id=legacy_account_id
)
-- not in legacy_records_in_bhe_provider
-- legacy_provider_external_id = location's site_code
,location_organization_update as (
select 
    legacy_provider_external_id,
    new_provider_external_id,
    site_code,
    location_id,
    location_type_code
 from hades_table_data_mapped_active_licenses_provider bhe    
    inner join dm_table_data_location on legacy_provider_external_id=site_code_compare
    where bhe.account_id not in (select account_id from legacy_records_in_bhe_provider)
    and location_type_code='organization'
) 
,location_organization_update_payload as (
select 
    new_provider_external_id LOC_ID, 
    parse_json(
        '{' || 
        '"location_id": "' || location_id || '",' || 
        '"site_code": "' || LOC_ID || '"' ||
        '}'
    ) payload
    from location_organization_update
) 
-- not in legacy_records_in_bhe_clinic
-- legacy_clinic_external_id = location's site_code
,location_facility_update as (
select 
    legacy_clinic_external_id,
    new_clinic_external_id,
    site_code,
    location_id,
    location_type_code
 from hades_table_data_mapped_active_licenses_clinic bhe    
    inner join dm_table_data_location on legacy_clinic_external_id=site_code_compare
    where bhe.account_id not in (select account_id from legacy_records_in_bhe_clinic)
    and location_type_code='facility'
)
,location_facility_update_payload as (
select 
    new_clinic_external_id LOC_ID, 
    parse_json(
        '{' || 
        '"location_id": "' || location_id || '",' || 
        '"site_code": "' || LOC_ID || '"' ||
        '}'
    ) payload
    from location_facility_update
) 
-- not in legacy_records_in_bhe_clinic
-- legacy_clinic_external_id+'facilitydata'= location's site_code
,location_facility_data_update as (
select 
    legacy_clinic_external_id,
    new_clinic_external_id,
    site_code,
    location_id,
    location_type_code
 from hades_table_data_mapped_active_licenses_clinic bhe    
    inner join dm_table_data_location on legacy_clinic_external_id||'facilitydata'=site_code_compare
    where bhe.account_id not in (select account_id from legacy_records_in_bhe_clinic)
    and location_type_code='facility_data'
)
,location_facility_data_update_payload as (
select 
    new_clinic_external_id||'facility_data' LOC_ID, 
    parse_json(
        '{' || 
        '"location_id": "' || location_id || '",' || 
        '"site_code": "' || LOC_ID || '"' ||
        '}'
    ) payload
    from location_facility_data_update
) 
,final as (
    select * from location_organization_update_payload
    union
    select * from location_facility_update_payload
    union
    select * from location_facility_data_update_payload
)
select * from final order by loc_id