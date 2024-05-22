FROM python:3.10-alpine3.19
RUN apk update && apk upgrade
RUN python -m pip install --upgrade pip
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
ENTRYPOINT ["python", "health_check.py"]