create table work_activities (
    o_net_soc_code varchar(255),
    element_id varchar(255),
    element_name varchar(255),
    scale_id varchar(255),
    data_value float,
    n float,
    standard_error float,
    lower_ci_bound float,
    upper_ci_bound float,
    recommend_suppress boolean,
    not_relevant boolean,
    day date,
    domain_source varchar(255)
);
