{% macro get_domain_name() %}

    {% if target.name=='dev' %}
        {% set value = 'co-carecoordination-dev' %}
    {% elif target.name=='qa' %}
        {% set value = 'co-carecoordination-uat' %}
    {% elif target.name=='prod' %}
        {% set value = 'co-carecoordination' %}
    {% elif target.name=='test' %}
        {% set value = 'co-carecoordination-test' %}
    {% else %}
        {% set value = '' %}
    {% endif %}

    {{ return(value) }}

{% endmacro %}