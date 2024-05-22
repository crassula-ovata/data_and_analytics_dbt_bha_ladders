with dm_table_data_clinic as (
    select * from  {{ source('dm_table_data', 'CASE_CLINIC') }}
), 
dm_table_data_unit as (
    select * from  {{ source('dm_table_data', 'CASE_UNIT') }}
), 
dm_table_data_capacity as (
    select * from  {{ source('dm_table_data', 'CASE_CAPACITY') }}
), 
final as 
(
    select
        unit.parent_case_id as parent_case_id,
        'clinic' as parent_case_type,
        'extension' as parent_relationship,
        'parent' as parent_identifier,
        'capacity' as case_type,
        '' as external_id,
        '' as case_id,
        'Template Bed Group 1' as CASE_NAME,
        unit.owner_id as owner_id,
        clinic.display_name as clinic_case_name_display,
        'yes' as accepts_commcare_referrals,
        case
            when clinic.phone_referrals is null
                then 'No information available'
            else
                regexp_replace(clinic.phone_referrals, $$(\d{3})(\d{3})(\d{4})$$, $$(\1) \2-\3$$)
        end as clinic_phone_referrals_display,
        case
            when 
                clinic.mental_health_settings is not null
                and clinic.residential_services is not null
                    then 'Both Mental Health & Substance Use'
            when clinic.mental_health_settings is not null
                then 'Mental Health'
            when clinic.residential_services is not null
                then 'Substance Use'
            else ''
        end as clinic_type_of_care_display,
        coalesce(clinic.address_full, 'No information available') as clinic_address_full_display,
        nvl(clinic.transportation_service, 'No information available')  as clinic_transportation_service_display,
        case 
            when clinic.insurance is null then 'No information available'
            else replace(clinic.insurance, ' ', ', ') 
        end as clinic_insurance_display,
        'No information available' as gender_display,
        'No information available' as acuity_display,
        unit.last_updated_date_time_raw::string as clinic_availability_last_updated_date_time_raw,
        clinic.map_coordinates as clinic_map_coordinates,
        clinic.map_popup as clinic_map_popup,
        'https://www.commcarehq.org/a/co-carecoordination-' || {{get_domain_name()}} || '/app/v1/a1a67a223416440199f060b6a94d15a6/view_facility/?case_id=' as view_more_info_smartlink_referrals,
        'https://www.commcarehq.org/a/co-carecoordination-' || {{get_domain_name()}} || '/app/v1/1e8de29bae5745e99ed2fb1d1a55adac/view_facility/?case_id=' as view_more_info_smartlink_bed_tracker,
        '0' as open_beds,
        'open' as current_status,
        unit.gender as unit_gender,
        unit.population_served as unit_population_served,
        unit.id as unit_case_ids
    from 
        dm_table_data_unit unit
        inner join dm_table_data_clinic clinic
        on unit.parent_case_id = clinic.case_id 
        and
        unit.case_id not in 
            (select unit_case_ids from dm_table_data_capacity)
        and unit.closed = false
) 
select
    parent_case_id,
    parent_case_type,
    parent_relationship,
    parent_identifier,
    case_type,
    external_id,
    case_id,
    case_name,
    owner_id,
    clinic_case_name_display,
    accepts_commcare_referrals,
    clinic_phone_referrals_display,
    clinic_type_of_care_display,
    clinic_address_full_display,
    clinic_transportation_service_display,
    clinic_insurance_display,
    gender_display,
    acuity_display,
    clinic_availability_last_updated_date_time_raw,
    clinic_map_coordinates,
    clinic_map_popup,
    view_more_info_smartlink_referrals,
    view_more_info_smartlink_bed_tracker,
    open_beds,
    current_status,
    unit_gender,
    unit_population_served,
    unit_case_ids 
from final