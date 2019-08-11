#!/bin/bash -eu

main () {

  delete_ecr_repository
  delete_ecs_taskdef
  delete_events_target
  delete_events_rule
}

delete_ecr_repository () {

  aws ecr delete-repository \
    --repository-name tasks-${TASK_NAME}-${TASK_ENV} \
    --force \
  ;
}

delete_ecs_taskdef () {

  aws cloudformation delete-stack \
    --stack-name cf-stack-ecs-taskdef-tasks-${TASK_NAME}-${TASK_ENV} \
  ;
}

delete_events_target () {

  aws events remove-targets \
    --rule events-rule-tasks-${TASK_NAME}-${TASK_ENV} \
    --ids ecs-targets-${TASK_NAME}-${TASK_ENV} \
  ;
}

delete_events_rule () {

  aws events delete-rule \
    --name events-rule-tasks-${TASK_NAME}-${TASK_ENV} \
  ;
}

main "$@"