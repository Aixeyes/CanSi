FROM continuumio/miniconda3

WORKDIR /app

COPY environment.yml /app/environment.yml

RUN conda env create -f /app/environment.yml

SHELL ["conda", "run", "-n", "appenv", "/bin/bash", "-c"]

COPY . /app

CMD ["conda", "run", "-n", "appenv", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

