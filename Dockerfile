FROM python:3.9
WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir fastapi uvicorn boto3 python-dotenv
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80", "--reload"]
