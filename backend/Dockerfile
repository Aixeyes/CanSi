FROM continuumio/miniconda3:latest

WORKDIR /app

# Create conda env first to leverage Docker layer caching
COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml && conda clean -afy

COPY . /app

ENV PATH="/opt/conda/envs/appenv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8000
