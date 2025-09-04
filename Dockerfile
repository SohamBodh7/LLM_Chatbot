# Stage 1: Builder - Installs dependencies and downloads the ML model
FROM python:3.10-slim AS builder

WORKDIR /app

# Install build tools needed for some Python packages, then clean up
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*

# Install a CPU-only version of PyTorch to avoid large downloads and timeouts.
# This is a dependency for sentence-transformers.
RUN pip install torch --no-cache-dir --index-url https://download.pytorch.org/whl/cpu

# Copy and install the rest of the Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy and run the model pre-loader script to cache the model into this layer
COPY preload_models.py .
RUN python preload_models.py

# ---
COPY .streamlit /app/.streamlit


# Stage 2: Final Application Image - A lean image with the app and its pre-built dependencies
FROM python:3.10-slim

WORKDIR /app

# Copy installed packages from the builder stage
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# Copy executables (like streamlit) installed by pip from the builder stage
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the pre-downloaded and cached model from the builder stage
# The default cache directory for sentence-transformers is /root/.cache/huggingface
COPY --from=builder /root/.cache /root/.cache

# Copy the main application file
COPY chatbot.py .

# The VOLUME instruction tells Docker that the data in these directories should be persisted.
VOLUME /app/document_library
VOLUME /app/vector_stores

# Expose the port Streamlit runs on
EXPOSE 8501

# The command to run when the container starts
CMD ["streamlit", "run", "chatbot.py", "--server.port=8501", "--server.address=0.0.0.0"]