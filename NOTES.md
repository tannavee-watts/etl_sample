Additional features that could be added:
1. Split the task into two portions: Do Extraction and Transformation in ECS and save file to s3. Expose S3 location as a spectrum partition (external schema in redshift)
2. Have the spectrum table partitioned by date
3. Have a separate task running periodically (daily, preferably before the ETL Task fires) that will expose the day's prefix on s3 as a partition to spectrum.
4. For Loading, have a Glue script that reads data from the s3 locations that belong to the spectrum table, do a final pass over the contents of the table, map the dynamic frame to the correct data types and write it to redshift as a table.
5. Configure a redshift cluster and use that instead of a postgres connection.


