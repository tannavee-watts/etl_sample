# etl_sample


1. Export all secrets required for this task using template (`secrets.env`)
2. Run the setup.sh script as `TASK_NAME=etl TASK_ENV=prod ./setup`. This will launch all ecs related resources, and set up a cloudwatch log group 
3. From the AWS Console, go to ECS and launch the task using Fargate Launch Type, and the security group, subnet and VPC Cluster you have set up.
4. Task will write logs to the log group created in the setup step
5. To run on a schedule, enable CloudWatch Scheduled Rule. The cron expression in the setup script will set the task to run at UTC 9 AM every morning


Additional Steps To Test Locally:
1. `docker build -t etltask .`
2. `docker run --env-file secrets.env etltask`
OR `python etl.py`
