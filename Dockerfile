# Start from a minimal base image
FROM debian:buster-slim AS build

# Set the working directory
WORKDIR /app

# Install dependencies for downloading and installing Miniconda
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and install Miniconda (minimized)
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /miniconda && \
    rm /tmp/miniconda.sh

# Add conda to PATH
ENV PATH=/miniconda/bin:$PATH

# Install anaconda-project in the base environment
RUN conda install -y anaconda-project && \
    conda clean -afy  # Clean up conda caches

# Copy project files (assuming anaconda-project.yml is in the source code)
COPY . /app/project

# Set up environment based on anaconda-project
ARG ENV_SPEC=""
RUN cd /app/project && \
    if [ -n "$ENV_SPEC" ]; then \
        anaconda-project prepare --env-spec $ENV_SPEC; \
    else \
        anaconda-project prepare; \
    fi

# Move the prepared environment to /app/env
RUN mv /app/project/envs/default /app/env

# Remove miniconda to reduce image size
RUN rm -rf /miniconda

# Remove any cached files, temporary or unnecessary files
RUN apt-get remove -y wget bzip2 ca-certificates && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Final stage: runtime image with only necessary files
FROM debian:buster-slim

# Set the working directory
WORKDIR /app/project

# Copy the prepared environment and project files from the build stage
COPY --from=build /app/env /app/env
COPY --from=build /app/project /app/project

ENV PATH=$PATH:/app/env/bin
ENV CONDA_PREFIX=/app/env
RUN ln -s /app/env /app/project/envs/default
# Activate the environment and set the entrypoint
ENTRYPOINT ["/bin/bash", "-c", "anaconda-project run \"$@\""]

# CMD is supplied at runtime using docker run

