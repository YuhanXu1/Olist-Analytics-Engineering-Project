FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

#install the packages
RUN pip install -r requirements.txt

ENV PYTHONPATH=/app/src

#use orchestrator to decide what command to run
#CMD ["python", "main.py"]