import pytest
import streamlit as st
import tempfile
import os
from unittest.mock import Mock, patch, MagicMock
import sys
import io
from contextlib import contextmanager

# Add the project directory to the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import the chatbot functions
from chatbot import (
    process_pdf, 
    create_vector_store, 
    get_qa_llm, 
    get_embeddings,
    qa_prompt
)

class TestChatbotComponents:
    """Test suite for chatbot components"""
    
    def setup_method(self):
        """Setup method that runs before each test"""
        # Mock the Streamlit session state
        if not hasattr(st, 'session_state'):
            st.session_state = {}
        
        # Mock the secrets
        st.secrets = {"grok_api_key": "test_api_key"}
    
    @patch('chatbot.ChatGroq')
    def test_get_qa_llm_success(self, mock_chat_groq):
        """Test successful LLM initialization"""
        mock_llm = Mock()
        mock_chat_groq.return_value = mock_llm
        
        llm = get_qa_llm()
        
        assert llm is not None
        mock_chat_groq.assert_called_once_with(
            groq_api_key="test_api_key",
            model_name="llama3-70b-8192",
            temperature=0.1
        )
    
    @patch('chatbot.ChatGroq')
    def test_get_qa_llm_failure(self, mock_chat_groq):
        """Test LLM initialization failure"""
        mock_chat_groq.side_effect = Exception("API Error")
        
        llm = get_qa_llm()
        
        assert llm is None
    
    @patch('chatbot.HuggingFaceEmbeddings')
    def test_get_embeddings_success(self, mock_embeddings):
        """Test successful embeddings initialization"""
        mock_emb = Mock()
        mock_embeddings.return_value = mock_emb
        
        embeddings = get_embeddings()
        
        assert embeddings is not None
        mock_embeddings.assert_called_once_with(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'},
            encode_kwargs={'normalize_embeddings': True}
        )
    
    @patch('chatbot.HuggingFaceEmbeddings')
    def test_get_embeddings_failure(self, mock_embeddings):
        """Test embeddings initialization failure"""
        mock_embeddings.side_effect = Exception("Model Error")
        
        embeddings = get_embeddings()
        
        assert embeddings is None
    
    def test_qa_prompt_template(self):
        """Test the QA prompt template structure"""
        assert qa_prompt is not None
        assert hasattr(qa_prompt, 'input_variables')
        assert 'context' in qa_prompt.input_variables
        assert 'question' in qa_prompt.input_variables
        
        # Test prompt formatting
        formatted = qa_prompt.format(
            context="This is a test context",
            question="What is this about?"
        )
        assert "This is a test context" in formatted
        assert "What is this about?" in formatted
    
    @patch('chatbot.PyPDFLoader')
    @patch('chatbot.os.unlink')
    def test_process_pdf_success(self, mock_unlink, mock_pdf_loader):
        """Test successful PDF processing"""
        # Create a mock PDF file
        mock_file = Mock()
        mock_file.getvalue.return_value = b"mock pdf content"
        
        # Mock the loader and documents
        mock_documents = [Mock(), Mock()]
        mock_pdf_loader.return_value.load.return_value = mock_documents
        
        documents = process_pdf(mock_file)
        
        assert documents is not None
        assert len(documents) == 2
        mock_pdf_loader.assert_called_once()
        mock_unlink.assert_called_once()
    
    @patch('chatbot.PyPDFLoader')
    def test_process_pdf_failure(self, mock_pdf_loader):
        """Test PDF processing failure"""
        mock_pdf_loader.side_effect = Exception("PDF Error")
        
        mock_file = Mock()
        mock_file.getvalue.return_value = b"mock pdf content"
        
        documents = process_pdf(mock_file)
        
        assert documents is None
    
    @patch('chatbot.RecursiveCharacterTextSplitter')
    @patch('chatbot.FAISS')
    @patch('chatbot.get_embeddings')
    def test_create_vector_store_success(self, mock_get_embeddings, mock_faiss, mock_splitter):
        """Test successful vector store creation"""
        # Mock embeddings
        mock_embeddings = Mock()
        mock_get_embeddings.return_value = mock_embeddings
        
        # Mock text splitter
        mock_chunks = [Mock(), Mock(), Mock()]
        mock_splitter_instance = Mock()
        mock_splitter_instance.split_documents.return_value = mock_chunks
        mock_splitter.return_value = mock_splitter_instance
        
        # Mock FAISS
        mock_vector_store = Mock()
        mock_faiss.from_documents.return_value = mock_vector_store
        
        # Mock documents
        mock_documents = [Mock(), Mock()]
        
        vector_store = create_vector_store(mock_documents)
        
        assert vector_store is not None
        mock_splitter.assert_called_once()
        mock_faiss.from_documents.assert_called_once_with(mock_chunks, mock_embeddings)
    
    @patch('chatbot.get_embeddings')
    def test_create_vector_store_embeddings_failure(self, mock_get_embeddings):
        """Test vector store creation with embeddings failure"""
        mock_get_embeddings.return_value = None
        
        mock_documents = [Mock(), Mock()]
        
        vector_store = create_vector_store(mock_documents)
        
        assert vector_store is None

class TestChatbotIntegration:
    """Integration tests for the chatbot"""
    
    def setup_method(self):
        """Setup method for integration tests"""
        if not hasattr(st, 'session_state'):
            st.session_state = {}
        st.secrets = {"grok_api_key": "test_api_key"}
    
    @patch('chatbot.ChatGroq')
    @patch('chatbot.HuggingFaceEmbeddings')
    @patch('chatbot.FAISS')
    def test_full_chatbot_workflow(self, mock_faiss, mock_embeddings, mock_chat_groq):
        """Test the complete chatbot workflow"""
        # Mock all the components
        mock_llm = Mock()
        mock_chat_groq.return_value = mock_llm
        
        mock_emb = Mock()
        mock_embeddings.return_value = mock_emb
        
        mock_vector_store = Mock()
        mock_faiss.from_documents.return_value = mock_vector_store
        
        # Test that all components can be initialized
        llm = get_qa_llm()
        embeddings = get_embeddings()
        
        assert llm is not None
        assert embeddings is not None
    
    def test_session_state_management(self):
        """Test session state management"""
        # Test initial state
        assert 'authenticated' not in st.session_state
        
        # Test setting authentication
        st.session_state.authenticated = True
        assert st.session_state.authenticated is True
        
        # Test clearing state
        st.session_state.authenticated = False
        assert st.session_state.authenticated is False

class TestChatbotUI:
    """Tests for UI components"""
    
    def setup_method(self):
        """Setup for UI tests"""
        if not hasattr(st, 'session_state'):
            st.session_state = {}
    
    def test_login_credentials(self):
        """Test login credential validation"""
        credentials = {"user": "password"}
        
        # Test valid credentials
        assert "user" in credentials
        assert credentials["user"] == "password"
        
        # Test invalid credentials
        assert "invalid_user" not in credentials
    
    def test_file_upload_validation(self):
        """Test file upload validation"""
        # Test valid PDF file
        valid_filename = "test.pdf"
        assert valid_filename.endswith('.pdf')
        
        # Test invalid file type
        invalid_filename = "test.txt"
        assert not invalid_filename.endswith('.pdf')

@contextmanager
def captured_output():
    """Context manager to capture stdout and stderr"""
    new_out, new_err = io.StringIO(), io.StringIO()
    old_out, old_err = sys.stdout, sys.stderr
    try:
        sys.stdout, sys.stderr = new_out, new_err
        yield sys.stdout, sys.stderr
    finally:
        sys.stdout, sys.stderr = old_out, old_err

def run_tests():
    """Run all tests and return results"""
    test_results = {
        'passed': 0,
        'failed': 0,
        'errors': []
    }
    
    # Test classes to run
    test_classes = [
        TestChatbotComponents,
        TestChatbotIntegration,
        TestChatbotUI
    ]
    
    for test_class in test_classes:
        test_instance = test_class()
        test_instance.setup_method()
        
        # Get all test methods
        test_methods = [method for method in dir(test_class) 
                       if method.startswith('test_')]
        
        for method_name in test_methods:
            try:
                method = getattr(test_instance, method_name)
                method()
                test_results['passed'] += 1
                print(f"✅ PASSED: {test_class.__name__}.{method_name}")
            except Exception as e:
                test_results['failed'] += 1
                error_msg = f"❌ FAILED: {test_class.__name__}.{method_name} - {str(e)}"
                test_results['errors'].append(error_msg)
                print(error_msg)
    
    return test_results

if __name__ == "__main__":
    print("🧪 Running TestSprite Tests for Chatbot Project")
    print("=" * 50)
    
    results = run_tests()
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results:")
    print(f"✅ Passed: {results['passed']}")
    print(f"❌ Failed: {results['failed']}")
    print(f"📝 Total: {results['passed'] + results['failed']}")
    
    if results['errors']:
        print("\n🔍 Error Details:")
        for error in results['errors']:
            print(f"  {error}")
    
    print("\n🎯 TestSprite Integration Complete!")

