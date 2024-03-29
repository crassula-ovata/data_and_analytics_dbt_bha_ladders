with
dm_table_data_provider as (
      select * from  {{ source('dm_table_data', 'CASE_PROVIDER') }}
), 
hades_table_data_ladders_active_licenses as (
      select * from  {{ source('hades_table_data', 'VWS_LADDERS_ACTIVE_LICENSES') }}
), 

p_share as (
    select 
        distinct
        dm.external_id_format (parent_account_id) as parent_account_id,
        bha_general_acct 
    from hades_table_data_ladders_active_licenses
 --   where parent_account_id = '0014m_00001hh_zzl_q_a_s_'
        order by BHA_GENERAL_ACCT asc
),

p_share_otp as (
    select 
        dm.external_id_format (parent_account_id) as parent_account_id,
        listagg(opioid_treatment_programs) as opioid_treatment_provider_agg,
        contains(opioid_treatment_provider_agg, 'true') as opioid_treatment_provider
        
     from hades_table_data_ladders_active_licenses --where parent_account_id = '0016100001h_a_07x_a_a_t_'
     group by parent_account_id

),

p_prod as (
   
    select * from (
     select 
        distinct
        case_id, 
        trim(external_id) as external_id, 
        date_opened, 
        case_name,
        rank () over ( partition by external_id order by date_opened asc ) as date_rank_p,
        opioid_treatment_provider
        
     from dm_table_data_provider p1 where closed = 'FALSE' and external_id is not null) where date_rank_p = 1 
),

new_providers as (

    select 
        null as n_date_opened,
        p_prod.case_id,
        p_share.parent_account_id as external_id,

        {% if target.name=='dev' %}
            '{{ var('owner_id_provder_dev') }}'
        {% elif target.name=='qa' %}
            '{{ var('owner_id_provder_qa') }}'
        {% elif target.name=='prod' %}
            '{{ var('owner_id_provder_prod') }}'
        {% elif target.name=='test-location' %}
            '{{ var('owner_id_provder_test_location') }}'
        {% else %}
            '{{ var('owner_id_provder_test') }}'
        {% endif %}
        as owner_id,
        --'775d5b8c5f1147a6867dfa9ec2c6157e' as owner_id,

        'provider' as case_type,
        p_share.bha_general_acct as case_name,
        p_share_otp.opioid_treatment_provider,
        null as update_name_action, 
        null as update_otp_action,
        case when external_id is null then 'create' else null end as action,
    current_timestamp() as import_date
    from p_share left join p_prod on p_share.parent_account_id = p_prod.external_id 
                 left join p_share_otp on p_share_otp.parent_account_id = p_share.parent_account_id
    where action = 'create'
    order by case_name
), 

updated_providers as (

    select 
        p_prod.date_opened as u_date_opened,
        p_prod.case_id,
        p_prod.external_id,

        {% if target.name=='dev' %}
            '{{ var('owner_id_provder_dev') }}'
        {% elif target.name=='qa' %}
            '{{ var('owner_id_provder_qa') }}'
        {% elif target.name=='prod' %}
            '{{ var('owner_id_provder_prod') }}'
        {% elif target.name=='test-location' %}
            '{{ var('owner_id_provder_test_location') }}'
        {% else %}
            '{{ var('owner_id_provder_test') }}'
        {% endif %}
        as owner_id,        
        --'775d5b8c5f1147a6867dfa9ec2c6157e' as owner_id,
        
        'provider' as case_type,
        p_share.bha_general_acct as case_name,
        iff(p_share_otp.opioid_treatment_provider = p_prod.opioid_treatment_provider, p_prod.opioid_treatment_provider,                                             p_share_otp.opioid_treatment_provider) as opioid_treatment_provider,
        iff(p_share.parent_account_id = p_prod.external_id and p_share.bha_general_acct <> p_prod.case_name, 'update_name', null) as                               name_action,
        iff(p_share.parent_account_id = p_prod.external_id and nvl(p_share_otp.opioid_treatment_provider::string,'') <>             nvl(p_prod.opioid_treatment_provider::string, ''), 'update_otp', null) as otp_action,
        iff(name_action = 'update_name' or otp_action = 'update_otp', 'update', null) as action,
    current_timestamp() as import_date
    from p_share left join p_prod on  p_share.parent_account_id = p_prod.external_id
                 left join p_share_otp on p_share_otp.parent_account_id = p_share.parent_account_id
    where action like 'update' 
    order by case_name
),

final as (
select * from (select n_date_opened,case_id, external_id, owner_id, case_type, case_name, 
               case opioid_treatment_provider
                when TRUE then 'yes'
                when FALSE then 'no'
               else null end as opioid_treatment_provider, 
               update_name_action, update_otp_action, action, import_date from new_providers 
               union 
               select u_date_opened,case_id, external_id, owner_id, case_type, case_name,
               case opioid_treatment_provider
                when TRUE then 'yes'
                when FALSE then 'no'
               else null end as opioid_treatment_provider, name_action, otp_action, action, import_date from updated_providers)

order by action, external_id
)

select 
	N_DATE_OPENED,
	CASE_ID,
	EXTERNAL_ID,
	OWNER_ID,
	CASE_TYPE,
	CASE_NAME,
	OPIOID_TREATMENT_PROVIDER,
	UPDATE_NAME_ACTION,
	UPDATE_OTP_ACTION,
	ACTION,
	IMPORT_DATE
from final