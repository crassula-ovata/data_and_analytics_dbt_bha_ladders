{% macro create_fn_get_mental_health_settings() %}

CREATE OR REPLACE FUNCTION DM.fn_get_mental_health_settings(
    "HOSPITAL" BOOLEAN, 
    "EMERGENCY" BOOLEAN,
    "TREATMENT_EVALUATION_72_HOUR"  BOOLEAN,
    "RESIDENTIAL_LONG_TERM_TREATMENT"  BOOLEAN,
    "RESIDENTIAL_SHORT_TERM_TREATMENT"  BOOLEAN,
    -- "PSYCHIATRIC_RESIDENTIAL"  VARCHAR(16777216),
    "RESIDENTIAL_CHILD_CARE_FACILITY"  BOOLEAN,
    "CRISIS_STABILIZATION_UNIT"  BOOLEAN,
    "ACUTE_TREATMENT_UNIT" BOOLEAN )
    -- "DAY_TREATMENT"  VARCHAR(16777216),
    -- "COMMUNITY_MENTAL_HEALTH_CLINIC"  VARCHAR(16777216),
    -- "COMMUNITY_MENTAL_HEALTH_CENTER"  VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
AS '{{ fn_get_mental_health_settings() }}';
  
{% endmacro %}