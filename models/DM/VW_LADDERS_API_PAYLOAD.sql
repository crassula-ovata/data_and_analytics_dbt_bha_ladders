with payloads as (
    --12/1: BR updated logic to include clinic_display_name and additional logic for json
    --11/29: SL added for VW_UNIT_UPDATE start
    select case when nullif(CASE_ID,'') is null then EXTERNAL_ID else CASE_ID end PROV_ID, 
        CASE_TYPE, 
        parse_json(
'{ "create": false' || ', ' ||  
            case when nullif(CASE_ID,'') is null then '"external_id": ' else '"case_id": ' end || 
            case when nullif(CASE_ID,'') is null then '"' || 
            replace(replace(replace(EXTERNAL_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' else '"' || replace(replace(replace(CASE_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' end || 
            '"case_type": ' || '"' || 
            replace(replace(replace(CASE_TYPE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' || 
            '"owner_id": ' || '"' || 
            replace(replace(replace(OWNER_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' ||
            '"indices": ' || 
            '{ "parent": {' || 
                            case when nullif(PARENT_CASE_ID,'') is null then '"external_id": ' else '"case_id": ' end ||
                            case when nullif(PARENT_CASE_ID,'') is null then '"' || replace(replace(replace(EXTERNAL_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' else '"' || replace(replace(replace(PARENT_CASE_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' end ||
                            '"case_type": ' || '"' || replace(replace(replace(PARENT_CASE_TYPE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' ||
                            '"relationship": ' || '"' || replace(replace(replace(PARENT_RELATIONSHIP, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '" } },' ||
            trim(
            '"properties": {' ||
            case when nullif(map_coordinates,'') is not null 
                    then '"map_coordinates": ' || '"' ||
                    REPLACE(REPLACE(REPLACE(map_coordinates, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"' || ',' else '' end ||
            case when nullif(clinic_display_name,'') is not null 
                    then '"clinic_display_name": ' || ifnull('"' || replace(replace(replace(clinic_display_name, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""')  || ',' else '' end || 
            case when nullif(clinic_phone_display,'') is not null 
                    then '"clinic_phone_display": ' || ifnull('"' || replace(replace(replace(clinic_phone_display, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""')  || ',' else '' end || 
            case when nullif(clinic_address_full_display,'') is not null 
                    then '"clinic_address_full_display": ' || ifnull('"' || replace(replace(replace(clinic_address_full_display, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""')  || ',' else '' end || 
            case when nullif(clinic_mental_health_settings_display,'') is not null 
                    then '"clinic_mental_health_settings_display": ' || ifnull('"' || replace(replace(replace(clinic_mental_health_settings_display, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""')  || ',' else '' end || 
            case when nullif(map_popup,'') is not null 
                    then '"map_popup": ' || ifnull('"' || replace(replace(replace(map_popup, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""')  || ',' else '' end || 
            case when nullif(clinic_insurance_display,'') is not null 
                    then '"clinic_insurance_display": ' || ifnull('"' || replace(replace(replace(clinic_insurance_display, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""')  || ',' else '' end 
                    
               , ',' )    -- rtrim trailing comma from the key properties' values
                || ' } }') payload 
    from VW_UNIT_UPDATE
    union
    --11/29: SL added for VW_UNIT_UPDATE end
    select case when nullif(CASE_ID,'') is null then EXTERNAL_ID else CASE_ID end PROV_ID, 
        CASE_TYPE, -- use provider external id and case type to sort
        parse_json('{ "create": ' || (action = 'create')::string || ', ' ||  
                         case when nullif(CASE_ID,'') is null then '"external_id": ' else '"case_id": ' end || 
                         case when nullif(CASE_ID,'') is null then '"' || replace(replace(replace(EXTERNAL_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' else '"' || replace(replace(replace(CASE_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' end || 
                         '"case_name": ' || '"' || replace(replace(replace(replace(CASE_NAME, '\'','\\\''), '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' || '"case_type": ' || '"' || replace(replace(replace(CASE_TYPE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' || '"owner_id": ' || '"' || replace(replace(replace(OWNER_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' ||
                                '"properties": ' ||
                                '{ "import_date": ' || '"' || replace(replace(replace(IMPORT_DATE::string, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"' || 
                                case when UPDATE_OTP_ACTION is not null or action = 'create' 
                                        then ', "opioid_treatment_provider": "' || replace(replace(replace(OPIOID_TREATMENT_PROVIDER, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '",' else '' end || ' } }'
                               ) payload
    from VW_PROVIDERS_CREATE_UPDATE
    union
    select case when nullif(PARENT_CASE_ID,'') is null then PROVIDER_EXTERNAL_ID else PARENT_CASE_ID end PROV_ID,
        CASE_TYPE, -- use provider external id and case type to sort
        parse_json('{ "create": ' || (action = 'create')::string || ', ' ||  
                         case when nullif(PROD_CASE_ID,'') is null then '"external_id": ' else '"case_id": ' end || 
                         case when nullif(PROD_CASE_ID,'') is null then '"' || replace(replace(replace(LADDERS_EXTERNAL_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' else '"' || replace(replace(replace(PROD_CASE_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' end || 
                         case when CASE_NAME_ACTION is not null or action = 'create' then '"case_name": ' || '"' || replace(replace(replace(replace(CASE_NAME, '\'','\\\''), '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' else '' end || 
                         '"case_type": ' || '"' || replace(replace(replace(CASE_TYPE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' || '"owner_id": ' || '"' || replace(replace(replace(OWNER_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' ||
                                '"indices": ' || 
                                '{ "parent": {' || 
                                              case when nullif(PARENT_CASE_ID,'') is null then '"external_id": ' else '"case_id": ' end ||
                                              case when nullif(PARENT_CASE_ID,'') is null then '"' || replace(replace(replace(PROVIDER_EXTERNAL_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' else '"' || replace(replace(replace(PARENT_CASE_ID, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' end ||
                                              '"case_type": ' || '"' || replace(replace(replace(PARENT_CASE_TYPE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '", ' ||
                                              '"relationship": ' || '"' || replace(replace(replace(PARENT_RELATIONSHIP, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '" } },' ||
                                '"properties": {' ||
                                    case when COUNTY_ACTION is not null or action = 'create' and COUNTY is not null
                                        then '"county": ' || ifnull('"' || replace(replace(replace(COUNTY, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when ADDRESS_CITY_ACTION is not null or action = 'create' and ADDRESS_CITY is not null
                                        then '"address_city": ' || ifnull('"' || replace(replace(replace(ADDRESS_CITY, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when ADDRESS_FULL_ACTION is not null or action = 'create' and ADDRESS_FULL is not null
                                        then '"address_full": ' || ifnull('"' || replace(replace(replace(ADDRESS_FULL, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when ADDRESS_STATE_ACTION is not null or action = 'create' and ADDRESS_STATE is not null
                                        then '"address_state": ' || ifnull('"' || replace(replace(replace(ADDRESS_STATE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when ADDRESS_STREET_ACTION is not null or action = 'create' and ADDRESS_STREET is not null
                                        then '"address_street": ' || ifnull('"' || replace(replace(replace(ADDRESS_STREET, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when ADDRESS_ZIP_ACTION is not null or action = 'create' and ADDRESS_ZIP is not null
                                        then '"address_zip": ' || ifnull('"' || replace(replace(replace(ADDRESS_ZIP, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when CLINIC_TYPE_ACTION is not null or action = 'create' and CLINIC_TYPE is not null
                                        then '"clinic_type": ' || ifnull('"' || replace(replace(replace(CLINIC_TYPE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when DISPLAY_NAME_ACTION is not null or action = 'create' and DISPLAY_NAME is not null
                                        then '"display_name": ' || ifnull('"' || replace(replace(replace(replace(DISPLAY_NAME, '\'','\\\''), '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when OPIOID_TREATMENT_PROVIDER_ACTION is not null or action = 'create' and OPIOID_TREATMENT_PROVIDER is not null
                                        then '"opioid_treatment_provider": ' || ifnull('"' || replace(replace(replace(OPIOID_TREATMENT_PROVIDER, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when PHONE_NUMBER_ACTION is not null or action = 'create' and PHONE is not null
                                        then '"phone_number": ' || ifnull('"' || replace(replace(replace(PHONE, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when PHONE_DETAILS_ACTION is not null or action = 'create' and PHONE_DETAILS is not null
                                        then '"phone_details": ' || ifnull('"' || replace(replace(replace(PHONE_DETAILS, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when PHONE_DISPLAY_ACTION is not null or action = 'create' and PHONE_DISPLAY is not null
                                        then '"phone_display": ' || ifnull('"' || replace(replace(replace(PHONE_DISPLAY, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    -- case when SUBSTANCE_USE_SERVICES_ACTION is not null or action = 'create' and SUBSTANCE_USE_SERVICES is not null
                                    --     then '"substance_use_services": ' || ifnull('"' || replace(replace(replace(SUBSTANCE_USE_SERVICES, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                     --5/25 Updated for additional fields
                                    case when original_licensure_date_action is not null or action = 'create' and original_licensure_date is not null
                                        then '"original_licensure_date": ' || ifnull('"' || replace(replace(replace(original_licensure_date, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when sud_license_number_action is not null or action = 'create' and sud_license_number is not null
                                        then '"sud_license_number": ' || ifnull('"' || replace(replace(replace(sud_license_number, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when cs_license_number_action is not null or action = 'create' and cs_license_number is not null
                                        then '"cs_license_number": ' || ifnull('"' || replace(replace(replace(cs_license_number, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when mh_designation_action is not null or action = 'create' and mh_designation is not null
                                        then '"mh_designation": ' || ifnull('"' || replace(replace(replace(mh_designation, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when rsso_license_number_action is not null or action = 'create' and rsso_license_number is not null
                                        then '"rsso_license_number": ' || ifnull('"' || replace(replace(replace(rsso_license_number, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when offers_telehealth_action is not null or action = 'create' and offers_telehealth is not null
                                        then '"offers_telehealth": ' || ifnull('"' || replace(replace(replace(offers_telehealth, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when fax_number_action is not null or action = 'create' and fax_number is not null
                                        then '"fax_number": ' || ifnull('"' || replace(replace(replace(fax_number, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when tdd_tty_action is not null or action = 'create' and tdd_tty is not null
                                        then '"tdd_tty": ' || ifnull('"' || replace(replace(replace(tdd_tty, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when hide_address_action is not null or action = 'create' and hide_address is not null
                                        then '"hide_address": ' || ifnull('"' || replace(replace(replace(hide_address, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when provider_location_display_label_action is not null or action = 'create' and provider_location_display_label is not null
                                        then '"provider_location_display_label": ' || ifnull('"' || replace(replace(replace(provider_location_display_label, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when website_action is not null or action = 'create' and website is not null
                                        then '"website": ' || ifnull('"' || replace(replace(replace(website, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when population_served_action is not null or action = 'create' and population_served is not null
                                        then '"population_served": ' || ifnull('"' || replace(replace(replace(population_served, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when accessibility_action is not null or action = 'create' and accessibility is not null
                                        then '"accessibility": ' || ifnull('"' || replace(replace(replace(accessibility, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when npi_action is not null or action = 'create' and npi is not null
                                        then '"npi": ' || ifnull('"' || replace(replace(replace(npi, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when insurance_action is not null or action = 'create' and insurance is not null
                                        then '"insurance": ' || ifnull('"' || replace(replace(replace(insurance, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when language_services_action is not null or action = 'create' and language_services is not null
                                        then '"language_services": ' || ifnull('"' || replace(replace(replace(language_services, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when monday_hours_action is not null or action = 'create' and monday_hours is not null
                                        then '"monday_hours": ' || ifnull('"' || replace(replace(replace(monday_hours, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when monday_open_action is not null or action = 'create' and monday_open is not null
                                        then '"monday_open": ' || ifnull('"' || replace(replace(replace(monday_open, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when monday_close_action is not null or action = 'create' and monday_close is not null
                                        then '"monday_close": ' || ifnull('"' || replace(replace(replace(monday_close, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when tuesday_hours_action is not null or action = 'create' and tuesday_hours is not null
                                        then '"tuesday_hours": ' || ifnull('"' || replace(replace(replace(tuesday_hours, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when tuesday_open_action is not null or action = 'create' and tuesday_open is not null
                                        then '"tuesday_open": ' || ifnull('"' || replace(replace(replace(tuesday_open, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when tuesday_close_action is not null or action = 'create' and tuesday_close is not null
                                        then '"tuesday_close": ' || ifnull('"' || replace(replace(replace(tuesday_close, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when wednesday_hours_action is not null or action = 'create' and wednesday_hours is not null
                                        then '"wednesday_hours": ' || ifnull('"' || replace(replace(replace(wednesday_hours, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when wednesday_open_action is not null or action = 'create' and wednesday_open is not null
                                        then '"wednesday_open": ' || ifnull('"' || replace(replace(replace(wednesday_open, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when wednesday_close_action is not null or action = 'create' and wednesday_close is not null
                                        then '"wednesday_close": ' || ifnull('"' || replace(replace(replace(wednesday_close, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when thursday_hours_action is not null or action = 'create' and thursday_hours is not null
                                        then '"thursday_hours": ' || ifnull('"' || replace(replace(replace(thursday_hours, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when thursday_open_action is not null or action = 'create' and thursday_open is not null
                                        then '"thursday_open": ' || ifnull('"' || replace(replace(replace(thursday_open, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when thursday_close_action is not null or action = 'create' and thursday_close is not null
                                        then '"thursday_close": ' || ifnull('"' || replace(replace(replace(thursday_close, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when friday_hours_action is not null or action = 'create' and friday_hours is not null
                                        then '"friday_hours": ' || ifnull('"' || replace(replace(replace(friday_hours, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when friday_open_action is not null or action = 'create' and friday_open is not null
                                        then '"friday_open": ' || ifnull('"' || replace(replace(replace(friday_open, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when friday_close_action is not null or action = 'create' and friday_close is not null
                                        then '"friday_close": ' || ifnull('"' || replace(replace(replace(friday_close, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when saturday_hours_action is not null or action = 'create' and saturday_hours is not null
                                        then '"saturday_hours": ' || ifnull('"' || replace(replace(replace(saturday_hours, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when saturday_open_action is not null or action = 'create' and saturday_open is not null
                                        then '"saturday_open": ' || ifnull('"' || replace(replace(replace(saturday_open, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when saturday_close_action is not null or action = 'create' and saturday_close is not null
                                        then '"saturday_close": ' || ifnull('"' || replace(replace(replace(saturday_close, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when sunday_hours_action is not null or action = 'create' and sunday_hours is not null
                                        then '"sunday_hours": ' || ifnull('"' || replace(replace(replace(sunday_hours, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when sunday_open_action is not null or action = 'create' and sunday_open is not null
                                        then '"sunday_open": ' || ifnull('"' || replace(replace(replace(sunday_open, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when sunday_close_action is not null or action = 'create' and sunday_close is not null
                                        then '"sunday_close": ' || ifnull('"' || replace(replace(replace(sunday_close, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when circle_program_action is not null or action = 'create' and circle_program is not null
                                        then '"circle_program": ' || ifnull('"' || replace(replace(replace(circle_program, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when mso_affiliation is not null or action = 'create' and mso_affiliation is not null
                                        then '"mso_affiliation": ' || ifnull('"' || replace(replace(replace(mso_affiliation, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when rae_action is not null or action = 'create' and rae is not null
                                        then '"rae": ' || ifnull('"' || replace(replace(replace(rae, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when aso_action is not null or action = 'create' and aso is not null
                                        then '"aso": ' || ifnull('"' || replace(replace(replace(aso, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when provider_directory_form_modified_date_action is not null or action = 'create' and provider_directory_form_modified_date is not null
                                        then '"provider_directory_form_modified_date": ' || ifnull('"' || replace(replace(replace(provider_directory_form_modified_date, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when accepting_new_patients_action is not null or action = 'create' and accepting_new_patients is not null
                                        then '"accepting_new_patients": ' || ifnull('"' || replace(replace(replace(accepting_new_patients, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when telehealth_restrictions_action is not null or action = 'create' and telehealth_restrictions is not null
                                        then '"telehealth_restrictions": ' || ifnull('"' || replace(replace(replace(telehealth_restrictions, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when mental_health_settings_action is not null or action = 'create' and mental_health_settings is not null
                                        then '"mental_health_settings": ' || ifnull('"' || replace(replace(replace(mental_health_settings, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when residential_services_action is not null or action = 'create' and residential_services is not null
                                        then '"residential_services": ' || ifnull('"' || replace(replace(replace(residential_services, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when service_types_action is not null or action = 'create' and service_types is not null
                                        then '"service_types": ' || ifnull('"' || replace(replace(replace(service_types, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when latitude_action is not null or action = 'create' and latitude is not null
                                        then '"latitude": ' || ifnull('"' || replace(replace(replace(latitude, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when longitude_action is not null or action = 'create' and longitude is not null
                                        then '"longitude": ' || ifnull('"' || replace(replace(replace(longitude, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when map_coordinates_action is not null or action = 'create' and map_coordinates is not null
                                        then '"map_coordinates": ' || ifnull('"' || replace(replace(replace(map_coordinates, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    case when gender_action is not null or action = 'create' and gender is not null
                                        then '"gender": ' || ifnull('"' || replace(replace(replace(gender, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"','""') || ',' else '' end ||
                                    --12/1: SL added for tile_header
                                    --12/4: BR removed/commented out tile_header. Will be added to Unit cases instead. 
                                    -- '"tile_header": "' || replace(replace(replace(tile_header::string, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"' || ',' ||

                                    '"import_date": "' || replace(replace(replace(IMPORT_DATE::string, '"', '\\"'), '\n', '\\n'), '\r', '\\r') || '"' ||
                                                            '} }'
                                                           ) payload
                                    from VW_CLINICS_CREATE_UPDATE 
)
, numbered_payloads as ( --add row numbers and groupings of 100 at a time
  select row_number() over(order by PROV_ID asc, case_type desc) rownum, ceil(rownum/100) grouping, payload from payloads
),
final as (
select grouping, '[' || listagg(payload::string, ',') || ']' payload --concatenate payloads into arrays of up to 100
from numbered_payloads group by 1 order by 1
)

select 
	GROUPING,
	PAYLOAD
from final