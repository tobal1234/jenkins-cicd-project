FROM python:3.12-slim

WORKDIR /app

COPY Oluwatoba.Lojede.py .

CMD ["python", "Oluwatoba.Lojede.py"]