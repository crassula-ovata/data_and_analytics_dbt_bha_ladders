with 
dm_table_data_unit as (
      select * from {{ source('dm_table_data', 'CASE_UNIT') }}
),
dm_table_data_clinic as (
      select * from  {{ source('dm_table_data', 'CASE_CLINIC') }}
),
dm_table_data_location as (
      select * from  {{ source('dm_table_data', 'LOCATION') }}
),
clinic_wo_unit as (
    select case_id from  dm_table_data_clinic where closed = false
    and case_id not in (select parent_case_id from dm_table_data_unit where closed=false)
),
final as
(
    select
        clinic.case_name as parent_case_name,
        clinic.case_id as parent_case_id,
        clinic.external_id::string as parent_external_id,
        'clinic' as parent_case_type,
        'extension' as parent_relationship,
        'parent' as parent_identifier,
        null as external_id,
        'unit' as case_type,
        null as case_id,
        loc.id as owner_id,
        'Template Unit 1' as case_name,
        'template_unit_1' as unit_name_no_spaces,
        clinic.residential_services as residential_services,
        clinic.population_served as population_served,
        clinic.accessibility as accessibility,
        clinic.case_name as clinic_display_name,
        clinic.gender as gender,
        'open' as current_status,
        '-1' as last_updated_date_time_raw, 
        '0' as open_beds_count
    from 
        dm_table_data_clinic clinic 
        inner join dm_table_data_location loc 
        on clinic.owner_id = loc.parent_location_id
        and
        loc.location_type_code = 'facility_data' 
        and clinic.closed = false
        and clinic.case_id in (select * from clinic_wo_unit)
) 
select
    PARENT_CASE_NAME,
    PARENT_CASE_ID,
    PARENT_EXTERNAL_ID,
    PARENT_CASE_TYPE,
    PARENT_RELATIONSHIP,
    PARENT_IDENTIFIER,
    EXTERNAL_ID,
    CASE_TYPE,
    CASE_ID,
    OWNER_ID, 
    CASE_NAME,
    UNIT_NAME_NO_SPACES,
    RESIDENTIAL_SERVICES,
    POPULATION_SERVED,
    ACCESSIBILITY,
    CLINIC_DISPLAY_NAME,
    GENDER,
    CURRENT_STATUS,
    LAST_UPDATED_DATE_TIME_RAW,
    OPEN_BEDS_COUNT
from final