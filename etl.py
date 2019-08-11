import boto3
from botocore.exceptions import ClientError
import csv
from datetime import datetime, timedelta
import os
import pandas as pd 
import psycopg2
import requests
import shutil
import sqlalchemy
import urllib.parse
import pandas.io.sql as psql
from psycopg2.extras import LoggingConnection
from sqlalchemy import create_engine


class ETL_Sample():

    def __init__(self, options):
        self.options = options
        self.s3_prefix = options['s3_prefix']
        self.tempdir = options['temp_dir']
        self.datestamp = options['datestamp']
        self.options['pg_config'] = {
            'pgdatabase': self.options['pgdatabase'],
            'pghost': self.options['pghost'],
            'pgport': self.options['pgport'],
            'pguser': self.options['pguser'],
            'pgpassword': self.options['pgpassword'],
            'aws_secret_access_key': self.options['aws_secret_access_key'],
            'aws_access_key_id': self.options['aws_access_key_id'],
        }


    def run(self):
        print ("Starting file download")
        path, file = self.download_file('https://www.onetcenter.org/dl_files/database/db_23_3_text/Work%20Activities.txt')
        s3_key = file
        print ("Starting database copy")
        self.load_to_database()

    def download_file(self, url):
        print ("Get filename from URL")
        file_name = urllib.parse.unquote(url.split('/')[-1]).replace(' ', '')
        local_filepath = os.path.join(self.tempdir, file_name)
        with requests.get(url, stream=True) as r:
            with open(local_filepath, 'wb') as f:
                shutil.copyfileobj(r.raw, f)
        print ("File saved to computer")
        return local_filepath, file_name

    def load_to_database(self):
        print ("Loading data to PostgreSQL Database")
        work_activities = pd.read_csv("temp/WorkActivities.txt", sep='\t', index_col=None) 
        work_activities.columns = map(str.lower, work_activities.columns)
        work_activities.columns = work_activities.columns.str.replace(' ', '_')
        work_activities.columns = work_activities.columns.str.replace('*', '_')

        work_activities['recommend_suppress'] = work_activities.recommend_suppress == 'Y'
        work_activities['not_relevant'] = work_activities.not_relevant == 'Y'
        work_activities['date'] = work_activities['date'].astype('datetime64[ns]')

        work_activities.to_csv(path_or_buf='temp/WorkActivities.csv', sep='\t')
        conn = psycopg2.connect(host="localhost", dbname="tanviwatts", user="tanviwatts")
        cur = conn.cursor()
        print ("Connection created to PostgreSQL Database")

        engine = create_engine(self.options['connection_string'])
        con = engine.connect()
        table_name = 'work_activities'
        engine.execute('DELETE from "work_activities"')
        work_activities.to_sql(table_name, con, index_label=None, if_exists = 'replace')
        conn.close()
        print ("Loading data to PostgreSQL Database completed")

def main():
  
    options = {
        's3_prefix': os.getenv('S3_PREFIX') or 'the_muse',
        'temp_dir': os.getenv('TEMP_DIR') or '/app/temp', #'/Users/tanviwatts/Code/etl_sample/temp', #
        'datestamp': os.getenv('DATESTAMP') or datetime.strftime(datetime.now() - timedelta(1), '%Y-%m-%d') ,
        'aws_access_key_id': os.getenv('AWS_ACCESS_KEY_ID'),
        'aws_secret_access_key': os.getenv('AWS_SECRET_ACCESS_KEY'),
        'pgport': os.getenv('PGPORT') or 5439,
        'pghost': os.getenv('PGHOST'),
        'pgpassword': os.getenv('PGPASSWORD'),
        'pguser': os.getenv('PGUSER'),
        'pgdatabase': os.getenv('PGDATABASE'),
        'connection_string': os.getenv('CONNECTION_STRING') or "postgresql+psycopg2://tanviwatts:@localhost:5432/tanviwatts",
    }
    etl_sample = ETL_Sample(options)
    etl_sample.run()


if __name__ == '__main__':
    main()
