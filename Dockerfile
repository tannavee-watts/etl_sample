FROM python:3.7
WORKDIR /app
RUN mkdir -p /app/temp
COPY . /app
RUN pip install -r requirements.txt

RUN apt-get update && apt-get install -y postgresql postgresql-contrib
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

COPY . .
CMD [ "python", "etl.py" ]



