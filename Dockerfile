# Use a lightweight base image
FROM debian:buster-slim

# Set environment variables
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install necessary system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    bzip2 \
    ca-certificates \
    sudo \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda3
ENV MINICONDA_VERSION=latest
ENV MINICONDA_PATH=/opt/miniconda
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -o miniconda.sh && \
    bash miniconda.sh -b -p $MINICONDA_PATH && \
    rm miniconda.sh

# Add conda binary to PATH
ENV PATH=$MINICONDA_PATH/bin:$PATH

# Install anaconda-project in the base (root) conda environment
RUN conda install -y anaconda-project && \
    conda clean -afy

# Copy your project files into the container
WORKDIR /app
COPY . /app

# Prepare environment (accepting an optional environment name)
ARG ENV_SPEC=default
RUN anaconda-project prepare --env-spec $ENV_SPEC

RUN mv $MINICONDA_PATH/envs/$ENV_SPEC /opt/conda_env
RUN rm -rf $MINICONDA_PATH
ENV PATH=/opt/conda_env/bin:$PATH

# Define the command to be run in the container
# The required command will be passed as an argument
# Set the ENTRYPOINT to accept the runtime command
ENTRYPOINT ["anaconda-project", "run"]

# Define CMD as an empty array so users are required to provide the command at runtime
CMD []

