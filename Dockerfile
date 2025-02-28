FROM python:3.12.9-slim

WORKDIR /service

COPY . ./

RUN pip install --ignore-installed  --disable-pip-version-check -e .

EXPOSE 8080

ENTRYPOINT ["python3", "main.py"]
