# TestSprite Integration for Chatbot Project

This document provides comprehensive guidance for testing your document-based chatbot project using TestSprite integration.

## 🎯 Overview

TestSprite provides automated testing capabilities for your chatbot application, covering:
- **API Integration Testing** - Groq API connectivity and LLM functionality
- **Document Processing Testing** - PDF processing and vector store creation
- **UI Component Testing** - Streamlit interface validation
- **Workflow Integration Testing** - End-to-end user workflows
- **Error Handling Testing** - Graceful failure scenarios

## 📁 Project Structure

```
chatbot_project/
├── chatbot.py                 # Main chatbot application
├── test_chatbot.py           # Unit tests for chatbot components
├── run_testsprite_tests.py   # TestSprite integration runner
├── testsprite_config.json    # TestSprite configuration
├── create_test_pdf.py        # Test PDF generator
├── requirements.txt          # Project dependencies
└── TESTSprite_README.md     # This file
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
pip install reportlab  # For test PDF generation
```

### 2. Generate Test Data

```bash
python create_test_pdf.py
```

This creates `test_document.pdf` for testing document processing capabilities.

### 3. Run TestSprite Tests

```bash
python run_testsprite_tests.py
```

### 4. Run Individual Unit Tests

```bash
python test_chatbot.py
```

## 🧪 Test Categories

### 1. API Integration Tests
- **Groq API Connection**: Validates API key configuration
- **LLM Initialization**: Tests ChatGroq model setup
- **Response Generation**: Verifies LLM response capabilities

### 2. Document Processing Tests
- **PDF Upload**: Tests file upload functionality
- **Text Extraction**: Validates PDF text extraction
- **Text Chunking**: Tests document splitting into chunks
- **Vector Store Creation**: Tests FAISS vector database setup

### 3. UI Component Tests
- **Login Authentication**: Tests user authentication flow
- **File Upload Validation**: Tests file type validation
- **Chat Interface**: Tests message input/output
- **Session State Management**: Tests Streamlit session handling

### 4. Workflow Integration Tests
- **Complete User Journey**: Tests full workflow from upload to chat
- **Error Handling**: Tests graceful failure scenarios
- **Performance Metrics**: Monitors response times and resource usage

## 📊 Test Reports

TestSprite generates comprehensive HTML reports including:
- **Test Results Summary**: Pass/fail statistics
- **Detailed Test Logs**: Individual test outcomes
- **Performance Metrics**: Response times and resource usage
- **Error Analysis**: Detailed failure information

Reports are saved as `testsprite_report_YYYY-MM-DD_HH-MM-SS.html`

## 🔧 Configuration

### TestSprite Configuration (`testsprite_config.json`)

```json
{
  "project_name": "Chatbot Project",
  "test_suite": {
    "name": "Chatbot Integration Tests",
    "version": "1.0.0"
  },
  "test_scenarios": [
    {
      "name": "API Integration Tests",
      "tests": [...]
    }
  ],
  "performance_metrics": {
    "response_time_threshold": 5000,
    "memory_usage_limit": "512MB"
  }
}
```

### Environment Setup

1. **API Key Configuration**: Ensure your Groq API key is properly configured
2. **Dependencies**: Install all required packages from `requirements.txt`
3. **Test Data**: Generate test PDF using `create_test_pdf.py`

## 🎯 Test Execution

### Running All Tests
```bash
python run_testsprite_tests.py
```

### Running Specific Test Categories
```bash
# Unit tests only
python test_chatbot.py

# API tests only
python -c "from test_chatbot import TestChatbotComponents; TestChatbotComponents().test_get_qa_llm_success()"
```

### Continuous Integration
```bash
# Run tests with exit codes for CI/CD
python run_testsprite_tests.py
echo $?  # Exit code: 0 = success, 1 = failure
```

## 📈 Performance Monitoring

TestSprite monitors:
- **Response Time**: API call response times
- **Memory Usage**: Application memory consumption
- **CPU Usage**: Processor utilization
- **Error Rates**: Failure frequency analysis

## 🔍 Debugging Tests

### Common Issues

1. **API Key Errors**
   ```python
   # Check API key configuration
   import streamlit as st
   print(st.secrets.get("grok_api_key"))
   ```

2. **Import Errors**
   ```bash
   # Install missing dependencies
   pip install -r requirements.txt
   ```

3. **PDF Processing Errors**
   ```bash
   # Regenerate test PDF
   python create_test_pdf.py
   ```

### Debug Mode
```bash
# Run with verbose output
python -v test_chatbot.py
```

## 🎨 Customizing Tests

### Adding New Test Cases

1. **Unit Tests**: Add methods to `TestChatbotComponents` class
2. **Integration Tests**: Add methods to `TestChatbotIntegration` class
3. **UI Tests**: Add methods to `TestChatbotUI` class

Example:
```python
def test_new_feature(self):
    """Test new chatbot feature"""
    # Test implementation
    result = some_function()
    assert result is not None
```

### Modifying Test Configuration

Edit `testsprite_config.json` to:
- Add new test scenarios
- Modify performance thresholds
- Update test data requirements

## 📋 Test Data Management

### Sample Test Documents
- `test_document.pdf`: Comprehensive research document
- Custom PDFs: Add your own test documents

### Test Questions
Predefined test questions in configuration:
- "What is the main topic of this document?"
- "Summarize the key points"
- "What are the conclusions?"

## 🔄 Continuous Testing

### Automated Test Execution
```bash
# Run tests every hour
crontab -e
0 * * * * cd /path/to/chatbot_project && python run_testsprite_tests.py
```

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Run TestSprite Tests
  run: python run_testsprite_tests.py
```

## 📞 Support

### TestSprite MCP Integration
Your TestSprite is configured via MCP (Model Context Protocol):
- **Server**: `testsprite-mcp`
- **API Key**: Configured in your MCP settings
- **Commands**: Available through Cursor IDE

### Getting Help
1. Check test logs in generated HTML reports
2. Review error messages in console output
3. Verify configuration in `testsprite_config.json`
4. Ensure all dependencies are installed

## 🎉 Success Criteria

Tests are considered successful when:
- ✅ All unit tests pass
- ✅ API integration tests succeed
- ✅ Document processing works correctly
- ✅ UI components function properly
- ✅ Workflow integration completes
- ✅ Performance metrics are within thresholds

## 📚 Additional Resources

- [TestSprite Documentation](https://testsprite.com/docs)
- [Streamlit Testing Guide](https://docs.streamlit.io/library/advanced-features/testing)
- [LangChain Testing](https://python.langchain.com/docs/use_cases/testing)
- [Groq API Documentation](https://console.groq.com/docs)

---

**Happy Testing! 🧪✨**

