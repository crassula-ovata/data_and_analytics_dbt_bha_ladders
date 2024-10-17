with 
dm_table_data_clinic as (
      select 
        replace(external_id, '_', '') as external_id_compare,
        * 
      from {{ source('dm_table_data', 'CASE_CLINIC') }} where closed = 'FALSE' and external_id is not null
) 
,dm_table_data_provider as (
      select 
        replace(external_id, '_', '') as external_id_compare,
        * 
      from  {{ source('dm_table_data', 'CASE_PROVIDER') }} where closed = 'FALSE' and external_id is not null
)
,hades_table_exclude_bhe_in_legacy_static_data as ( 
 /*
    select 
        LEGACY_PARENT_ACCOUNT_ID, 
        LEGACY_ACCOUNT_ID, 
        PARENT_ACCOUNT_ID, 
        ACCOUNT_ID,
        BHA_GENERAL_ACCT,
        ACCOUNT_NAME,
        PROVIDER_DIRECTORY_DISPLAY_NAME
        from HADES_PROD_BHA_DIMAGI_SHARE.DM.VWS_LADDERS_MAPPED_ACTIVE_LICENSES
    union
*/    
    select 
        '0016100001H9zsgAAB' as LEGACY_PARENT_ACCOUNT_ID,
        null as LEGACY_ACCOUNT_ID,
        '0014M00002QMFFLQA5' as PARENT_ACCOUNT_ID,
        '0014M00002QMGXBQA5' as ACCOUNT_ID,
        'Sample Therapy Services - General Account' as BHA_GENERAL_ACCT,
        'Sample Therapy Services' as ACCOUNT_NAME,
        'Sample Therapy Services' as PROVIDER_DIRECTORY_DISPLAY_NAME
    union
    select 
        '0016100001H9zsgAAB' as LEGACY_PARENT_ACCOUNT_ID,
        '0016100001HA3gwAAD' as LEGACY_ACCOUNT_ID,
        '0014M00002QMFFLQA5' as PARENT_ACCOUNT_ID,
        null as ACCOUNT_ID,
        'Sample Therapy Services - General Account' as BHA_GENERAL_ACCT,
        null as ACCOUNT_NAME,
        'Sample Therapy Services' as PROVIDER_DIRECTORY_DISPLAY_NAME    
)  
,hades_table_data_mapped_active_licenses_provider as (
      select 
        --replace(dm.external_id_format(legacy_parent_account_id), '_', '') || '-' || replace(dm.external_id_format(legacy_account_id), '_', '') as legacy_clinic_external_id,
        --dm.external_id_format(parent_account_id) || '-' || dm.external_id_format(account_id) as new_clinic_external_id,
        replace(dm.external_id_format(legacy_parent_account_id), '_', '') as legacy_provider_external_id,
        dm.external_id_format(parent_account_id) as new_provider_external_id,
        * from hades_table_exclude_bhe_in_legacy_static_data 
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
        * from hades_table_exclude_bhe_in_legacy_static_data 
      where legacy_parent_account_id is not null and legacy_account_id is not null
      and parent_account_id is not null and account_id is not null
)
,legacy_records_in_bhe_clinic as (
    select * from hades_table_data_mapped_active_licenses_clinic where parent_account_id=legacy_parent_account_id and account_id=legacy_account_id
)
-- not in legacy_records_in_bhe_provider
-- legacy_provider_external_id = provider case's external_id
,provider_case_update as (
select 
    legacy_provider_external_id,
    new_provider_external_id,
    dm_table_data_provider.external_id_compare,
    dm_table_data_provider.external_id,
    dm_table_data_provider.case_id,
    dm_table_data_provider.case_type,
    dm_table_data_provider.case_name,
    current_timestamp() as import_date
 from hades_table_data_mapped_active_licenses_provider bhe    
    inner join dm_table_data_provider on legacy_provider_external_id=dm_table_data_provider.external_id_compare
    where bhe.account_id not in (select account_id from legacy_records_in_bhe_provider)
) 
-- not in legacy_records_in_bhe_clinic
-- legacy_clinic_external_id = clinic case's external_id
,clinic_case_update as (
select 
    legacy_clinic_external_id,
    new_clinic_external_id,
    dm_table_data_clinic.external_id_compare,
    dm_table_data_clinic.external_id,
    dm_table_data_clinic.case_id,
    dm_table_data_clinic.case_type,
    dm_table_data_clinic.case_name,
    current_timestamp() as import_date
 from hades_table_data_mapped_active_licenses_clinic bhe    
    inner join dm_table_data_clinic on legacy_clinic_external_id=dm_table_data_clinic.external_id_compare
    where bhe.account_id not in (select account_id from legacy_records_in_bhe_clinic)
) 
,final_union as (
    select * from provider_case_update
    union
    select * from clinic_case_update
)
,final as (
 select count(*) count, case_type from final_union  
 group by case_type
)
--select * from final where count>0 and case_type='provider'
select * from final where count<1 or case_type!='provider'
