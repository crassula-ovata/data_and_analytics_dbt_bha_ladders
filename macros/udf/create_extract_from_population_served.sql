{% macro create_extract_from_population_served() %}

CREATE OR REPLACE FUNCTION DM.EXTRACT_FROM_POPULATION_SERVED("POPULATION_SERVED_ORIGINAL" VARCHAR(16777216), "GENDER" BOOLEAN)
    RETURNS VARCHAR(16777216)
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.10'
    HANDLER = 'extract_from_population_served'
AS '{{ extract_from_population_served() }}';
  
{% endmacro %}
