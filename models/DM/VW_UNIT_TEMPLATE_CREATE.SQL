with 
dm_table_data_unit as (
      select * from  {{ source('dm_table_data', 'CASE_UNIT') }}
),
dm_table_data_location as (
      select * from  {{ source('dm_table_data', 'LOCATION') }}
),

final as
(
    select
        -- parent/index properties
        clinic.case_name as parent_case_name,
        NULL as PARENT_CASE_ID,
        clinic.ladders_external_id::string as parent_external_id,
        'clinic' as PARENT_CASE_TYPE,
        'extension' as PARENT_RELATIONSHIP,
        'parent' as parent_identifier,
        ----- Unit properties
        null as external_id,
        'unit' as CASE_TYPE,
        null as CASE_ID,
        loc.id as OWNER_ID, --unit owner_id
        'Template Unit 1' as CASE_NAME,
        'template_unit_1' as unit_name_no_spaces,
        clinic.residential_services as residential_services,
        clinic.population_served as population_served,
        clinic.accessibility as accessibility,
        clinic.case_name as clinic_display_name,
        clinic.gender as gender,
        'open' as current_status,
        'yes' as clinic_accepts_commcare_referrals,
        '-1' as last_updated_date_time_raw, 
        '0' as open_beds_count
    from 
        dm.VW_CLINICS_CREATE_UPDATE clinic 
        inner join 
        dm_table_data_location loc 
        on (clinic.ladders_external_id || 'facility_data') = loc.site_code
        and
        loc.location_type_code = 'facility_data' 
        and clinic.action = 'create' 
        and clinic.owner_id is not null
        -- and clinic.facility_data_id is not null ??
) 
select
    PARENT_CASE_NAME,
    PARENT_CASE_ID,
    parent_external_id,
    PARENT_CASE_TYPE,
    PARENT_RELATIONSHIP,
    parent_identifier,
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
    CLINIC_ACCEPTS_COMMCARE_REFERRALS,
    LAST_UPDATED_DATE_TIME_RAW,
    OPEN_BEDS_COUNT
from final