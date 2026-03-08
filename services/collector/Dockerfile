FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY signaldesk_collector ./signaldesk_collector

CMD ["python", "-m", "signaldesk_collector.main", "metrics"]
