FROM python:3.12.10-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY notes ./notes
USER 10001:10001
EXPOSE 8000
CMD ["uvicorn", "notes.main:app", "--host", "0.0.0.0", "--port", "8000"]
