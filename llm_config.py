from langchain_groq import ChatGroq
from secret_key import grok_api_key
import streamlit as st

@st.cache_resource
def get_llm():
    """Initialize and return the ChatGroq LLM instance"""
    try:
        llm = ChatGroq(
            temperature=0,
            groq_api_key=grok_api_key,
            model_name="llama-3.1-70b-versatile"  # You can change this to your preferred model
        )
        return llm
    except Exception as e:
        st.error(f"Error initializing LLM: {e}")
        return None

# You can also add other common configurations here
DEFAULT_TEMPERATURE = 0
AVAILABLE_MODELS = [
    "llama-3.1-70b-versatile",
    "llama-3.1-8b-instant",
    "mixtral-8x7b-32768",
    "gemma-7b-it"
]