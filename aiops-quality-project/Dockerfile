FROM python:3.11-slim
WORKDIR /app

COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app/main.py /app/main.py

RUN mkdir -p /models
ENV MODEL_PATH=/models/model.pkl
ENV APP_NAME=aiops-quality-api
ENV DRIFT_THRESHOLD=0.9

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
