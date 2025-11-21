# preload_models.py
from langchain_community.embeddings import HuggingFaceEmbeddings

print("Pre-loading sentence-transformers/all-MiniLM-L6-v2 model...")
try:
    # This line triggers the download and caches the model
    HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )
    print("✅ Model downloaded and cached successfully.")
except Exception as e:
    print(f"❌ Error pre-loading model: {e}")
    # Fail the build if the model can't be downloaded
    exit(1)
