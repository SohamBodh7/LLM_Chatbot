📄 Document-Based LLM Chatbot
This is an interactive web application that allows you to "chat" with your PDF documents. Upload a PDF, and the application will use a powerful Large Language Model (LLM) to answer your questions based on the document's content. This project leverages the LangChain framework, the Groq API for high-speed inference, and Streamlit for the user interface.

✨ Features
User Authentication: A simple login system to secure access to the application.

PDF Upload: Easily upload any PDF document through a clean web interface.

Intelligent Q&A: Ask questions in natural language and receive context-aware answers.

Retrieval-Augmented Generation (RAG): The chatbot doesn't just guess; it finds the most relevant sections of your document to formulate its answers.

Source Highlighting: For every answer, you can view the specific text chunks from the source document that were used, ensuring transparency and trust.

Interactive Chat Interface: A familiar, chat-style interface to manage your conversation history.

⚙️ Architecture
The application is built on a modern RAG (Retrieval-Augmented Generation) architecture:

UI Layer (Streamlit): Provides the interactive web interface for user login, file uploads, and the chat display.

Orchestration Layer (LangChain): Acts as the "brain" of the application, connecting all the different components. It manages the flow from data ingestion to final answer generation.

Data Processing:

PDF Loading: PyPDFLoader is used to extract text from the uploaded document.

Text Splitting: RecursiveCharacterTextSplitter breaks the document into smaller, manageable chunks.

Embedding: HuggingFaceEmbeddings (specifically, sentence-transformers/all-MiniLM-L6-v2) converts these text chunks into numerical vectors.

Retrieval Layer (FAISS): A FAISS (Facebook AI Similarity Search) vector store is created in-memory. This index allows for extremely fast and efficient searching to find the text chunks most semantically similar to a user's question.

Generation Layer (Groq): The user's question and the retrieved text chunks are sent to a powerful LLM (e.g., llama3-70b-8192) via the high-speed Groq API, which generates a coherent, context-aware answer.

🚀 Setup and Installation
Follow these steps to get the project running on your local machine.

1. Prerequisites
Python 3.8 or higher

An API key from Groq

2. Clone the Repository
git clone [https://your-repository-url.git](https://your-repository-url.git)
cd document-chatbot-project


3. Create a Virtual Environment
It's highly recommended to use a virtual environment to manage project dependencies.

# For Windows
python -m venv venv
venv\Scripts\activate

# For macOS/Linux
python3 -m venv venv
source venv/bin/activate


4. Install Dependencies
Install all the required Python packages from the requirements.txt file.

pip install -r requirements.txt


5. Configure Your API Key
You need to provide your Groq API key. Create a new file named secret_key.py in the root of the project directory.

Inside secret_key.py, add the following line, replacing "YOUR_GROQ_API_KEY" with your actual key:

# secret_key.py
grok_api_key = "YOUR_GROQ_API_KEY"


⚠️ Security Warning: The .gitignore file is already configured to ignore secret_key.py. Do not commit this file to any public repository.

▶️ How to Run
Once the setup is complete, you can run the Streamlit application with the following command:

streamlit run chatbot.py


Your web browser should automatically open to the application's URL (usually http://localhost:8501).

👤 Usage:
Login: The application will first present a login screen. Use the following credentials to log in:

Username: user

Password: password

Upload: Click the "Choose a PDF file" button to upload your document.

Process: After uploading, click the "Process Document" button. The app will read, chunk, and index the document's contents.

Ask Questions: Once processing is complete, the chat interface will become active. Type your questions into the input box at the bottom and press Enter.

View Sources: For each answer provided by the assistant, you can click the "View Sources" expander to see the exact parts of the document that were used to generate the response.
