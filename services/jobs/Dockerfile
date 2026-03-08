FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY signaldesk_jobs ./signaldesk_jobs
COPY migrations ./migrations

CMD ["python", "-m", "signaldesk_jobs.main", "run-once"]
