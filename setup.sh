#!/bin/bash -u

AWS_REGION='us-west-2'
SCHEDULE_EXPRESSION='cron(0 9 * * ? *)'
NETWORK_CONFIGURATION='{"awsvpcConfiguration":{"AssignPublicIp":"ENABLED","SecurityGroups":["'${AWS_NETWORKCONFIG_SECURITY_GROUP}'"],"Subnets":["'${AWS_NETWORKCONFIG_SUBNET}'"]}}'

main () {

  create_ecr_repository
  create_logs_group
  create_ecs_task_definition
  create_events_rule
  create_events_target
}

create_ecr_repository() {

  aws ecr create-repository \
    --repository-name tasks-${TASK_NAME}-${TASK_ENV} \
  ;

  # Upload folder to ECR Repository
  $(aws ecr get-login --no-include-email --region us-west-2)
  docker build -t tasks-${TASK_NAME}-${TASK_ENV} .
  docker tag tasks-${TASK_NAME}-${TASK_ENV}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/tasks-${TASK_NAME}-${TASK_ENV}:latest
  docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/tasks-${TASK_NAME}-${TASK_ENV}:latest
}

create_logs_group() {
  aws cloudformation create-stack \
    --stack-name cf-stack-logs-loggroup-tasks-${TASK_NAME}-${TASK_ENV} \
    --capabilities CAPABILITY_IAM \
    --template-body file://cft-logs-loggroup-tasks-${TASK_NAME}.yml \
    --parameters \
        ParameterKey=TaskEnv,ParameterValue=${TASK_ENV} \
        ParameterKey=TaskName,ParameterValue=${TASK_NAME} \
  ;
}
create_ecs_task_definition () {

  aws cloudformation create-stack \
    --stack-name cf-stack-ecs-taskdef-tasks-${TASK_NAME}-${TASK_ENV} \
    --capabilities CAPABILITY_IAM \
    --template-body file://cft-ecs-taskdef-tasks-${TASK_NAME}.yml \
    --parameters \
      ParameterKey=TaskEnv,ParameterValue=${TASK_ENV} \
      ParameterKey=TaskName,ParameterValue=${TASK_NAME} \
      ParameterKey=Datestamp,ParameterValue=${DATESTAMP} \
      ParameterKey=ContainerImageUrl,ParameterValue=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/tasks-${TASK_NAME}-${TASK_ENV}:latest \
      ParameterKey=RoleArn,ParameterValue=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole \
      ParameterKey=S3Prefix,ParameterValue=${S3_PREFIX} \
      ParameterKey=TempDir,ParameterValue=${TEMP_DIR} \
      ParameterKey=AwsAccessKeyId,ParameterValue=${AWS_ACCESS_KEY_ID} \
      ParameterKey=AwsSecretAccessKey,ParameterValue=${AWS_SECRET_ACCESS_KEY} \
      ParameterKey=PostgresUser,ParameterValue=${PGUSER} \
      ParameterKey=PostgresPassword,ParameterValue=${PGPASSWORD} \
      ParameterKey=PostgresDatabase,ParameterValue=${PGDATABASE} \
      ParameterKey=PostgresHost,ParameterValue=${PGHOST} \
      ParameterKey=PostgresPort,ParameterValue=${PGPORT} \
  ;
}

create_events_rule () {

  aws events put-rule \
    --name events-rule-tasks-${TASK_NAME}-${TASK_ENV} \
    --schedule-expression "${SCHEDULE_EXPRESSION}" \
    --description "Run ${TASK_NAME} every day at 09:00 UTC" \
    --state "DISABLED" \
  ;
}

create_events_target() {

  aws events put-targets \
    --rule events-rule-tasks-${TASK_NAME}-${TASK_ENV} \
    --targets '{"Arn":"arn:aws:ecs:'${AWS_REGION}':'${AWS_ACCOUNT_ID}':cluster/'${CLUSTER_NAME}'","EcsParameters":{"LaunchType":"FARGATE","NetworkConfiguration":'${NETWORK_CONFIGURATION}',"TaskCount": 1,"TaskDefinitionArn": "arn:aws:ecs:'${AWS_REGION}':'${AWS_ACCOUNT_ID}':task-definition/ecs-task-'${TASK_NAME}'-'${TASK_ENV}'"},"Id": "ecs-targets-'${TASK_NAME}'-'${TASK_ENV}'","RoleArn": "arn:aws:iam::'${AWS_ACCOUNT_ID}':role/ecsEventsRole"}' \
  ;
}


main "$@"