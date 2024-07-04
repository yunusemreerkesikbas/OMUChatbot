FROM python:3.8-slim

WORKDIR /app


COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]