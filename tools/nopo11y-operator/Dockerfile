# Use the official Python base image
FROM python:3.12.4-alpine

# Updated OS libraries
RUN apk update && apk upgrade --no-cache

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Copy the requirements.txt file and install dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy all the templates to the container
COPY templates ./templates/

# Copy the script into the container
COPY main.py ./

# Run the script
CMD ["kopf", "run", "-A", "--standalone", "./main.py"]

