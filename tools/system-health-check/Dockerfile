FROM python:3.12.4-alpine
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
ENTRYPOINT ["python", "health_check.py"]