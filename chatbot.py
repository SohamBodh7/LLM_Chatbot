import streamlit as st
from langchain_groq import ChatGroq
from langchain.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.vectorstores import FAISS
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
import os
import shutil

# --- Page Configuration ---
st.set_page_config(
    page_title="MES IMCC Info Chatbot",
    page_icon="🎓",
    layout="wide"
)

# --- Load the Groq API Key from Streamlit Secrets ---
try:
    grok_api_key = st.secrets["grok_api_key"]
except (KeyError, FileNotFoundError):
    st.error("🚨 Groq API Key not found. Please add it to your Streamlit secrets.")
    st.stop()

def setup_directories():
    """Create base directories for documents and vector stores if they don't exist."""
    os.makedirs("document_library", exist_ok=True)
    os.makedirs("vector_stores", exist_ok=True)

# --- Caching for Resource-Intensive Functions ---
@st.cache_resource
def get_qa_llm():
    """Initializes and caches the Language Model.
    It relies on the GROQ_API_KEY environment variable being set."""
    try:
        return ChatGroq(model_name="llama-3.3-70b-versatile", temperature=0.3)
    except Exception as e:
        st.error(f"Failed to initialize the language model: {e}")
        return None

@st.cache_resource
def get_embeddings():
    """Initializes and caches the text embedding model."""
    try:
        return HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'},
            encode_kwargs={'normalize_embeddings': True}
        )
    except Exception as e:
        st.error(f"Failed to initialize embeddings model: {e}")
        return None

# --- Prompt Template ---
qa_prompt = PromptTemplate(
    input_variables=["context", "question"],
    template="""
    You are an expert document analysis assistant. Your primary responsibility is to provide accurate, comprehensive, and helpful responses based solely on the provided document context.

    IMPORTANT INSTRUCTIONS:
    1. ANSWER ONLY from the provided context - never invent, assume, or use external knowledge
    2. If the context contains the answer, provide it completely and accurately
    3. If the context partially answers the question, clearly state what information is available and what is missing
    4. If the context doesn't contain relevant information, respond with: "I cannot find this information in the provided document."
    5. Always cite specific parts of the context when possible
    6. Maintain professional tone and clarity
    7. If the question is unclear, ask for clarification
    8. Adapt your response style to match the nature of the document content

    CONTEXT INFORMATION:
    {context}

    USER QUESTION:
    {question}

    RESPONSE:
    """
)

# ADMIN PAGE

def admin_page():
    """
    Admin interface for managing document categories and processing documents.
    """
    st.sidebar.title("Admin Panel")
    if st.sidebar.button("Logout"):
        st.session_state.authenticated = False
        st.session_state.role = None
        st.rerun()

    st.title("📄 Admin Document Management")
    st.write("Here you can create document categories and upload the relevant PDFs. After uploading, process the category to make it available to users.")

    # Get all available categories to be used across the admin page
    try:
        categories = [d for d in os.listdir("document_library") if os.path.isdir(os.path.join("document_library", d))]
    except FileNotFoundError:
        categories = []

    st.markdown("---")

    # --- Step 1: Create a New Category ---
    st.header("1. Create a New Category")
    new_category = st.text_input("Enter new category name (e.g., 'College Admission', 'Sports Events')")
    if st.button("Create Category"):
        if new_category:
            category_path = os.path.join("document_library", new_category)
            if not os.path.exists(category_path):
                os.makedirs(category_path)
                st.success(f"Category '{new_category}' created successfully!")
                st.rerun()
            else:
                st.warning(f"Category '{new_category}' already exists.")
        else:
            st.error("Category name cannot be empty.")

    st.markdown("---")

    # --- Step 2: Upload Documents to a Category ---
    st.header("2. Upload Documents to a Category")
    if not categories:
        st.info("No categories found. Please create a category first.")
    else:
        selected_category_for_upload = st.selectbox("Select Category to Upload Documents To", options=categories)
        # By using the selected category in the key, the file uploader will reset
        # its state (clear the file list) whenever a new category is chosen.
        uploaded_files = st.file_uploader(
            "Choose PDF files",
            type="pdf",
            accept_multiple_files=True,
            key=f"uploader_{selected_category_for_upload}")

        if st.button("Upload and Save Files"):
            if uploaded_files and selected_category_for_upload:
                save_path = os.path.join("document_library", selected_category_for_upload)
                for uploaded_file in uploaded_files:
                    with open(os.path.join(save_path, uploaded_file.name), "wb") as f:
                        f.write(uploaded_file.getbuffer())
                st.success(f"Saved {len(uploaded_files)} files to '{selected_category_for_upload}'.")

    st.markdown("---")

    # --- Step 3: Process a Category into Vector Store ---
    st.header("3. Process a Category into a Vector Store")
    st.warning("This step can be slow. It reads all PDFs in a category, splits them, and creates a searchable index. Only run this after you have finished uploading documents to a category.")
    
    if categories:
        selected_category_to_process = st.selectbox("Select Category to Process", options=categories, key="process_select")
        if st.button("Process Category"):
            if selected_category_to_process:
                with st.spinner(f"Processing '{selected_category_to_process}'... This may take a while."):
                    try:
                        doc_path = os.path.join("document_library", selected_category_to_process)
                        pdf_files = [f for f in os.listdir(doc_path) if f.endswith(".pdf")]
                        if not pdf_files:
                            st.error("No PDF files found in this category.")
                            st.stop()

                        all_documents = []
                        for pdf in pdf_files:
                            loader = PyPDFLoader(os.path.join(doc_path, pdf))
                            all_documents.extend(loader.load())

                        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1500, chunk_overlap=300)
                        chunks = text_splitter.split_documents(all_documents)
                        st.info(f"Split {len(all_documents)} pages into {len(chunks)} text chunks.")

                        embeddings = get_embeddings()
                        if embeddings is None: st.stop()

                        vector_store = FAISS.from_documents(chunks, embeddings)

                        vector_store_path = os.path.join("vector_stores", selected_category_to_process)
                        vector_store.save_local(vector_store_path)
                        st.success(f"✅ Category '{selected_category_to_process}' processed and saved successfully!")

                    except Exception as e:
                        st.error(f"An error occurred during processing: {e}")

    st.markdown("---")

    # --- Step 4: Delete a Category ---
    st.header("4. Delete a Category")
    st.error("⚠️ **DANGER ZONE:** Deleting a category is permanent and will remove all associated documents and the processed data index. This action cannot be undone.")

    if categories:
        selected_category_to_delete = st.selectbox("Select category to delete", options=[""] + categories, key="delete_select")
        if selected_category_to_delete:
            if st.button(f"Permanently Delete '{selected_category_to_delete}' Category"):
                try:
                    doc_path = os.path.join("document_library", selected_category_to_delete)
                    vector_store_path = os.path.join("vector_stores", selected_category_to_delete)

                    if os.path.exists(doc_path):
                        shutil.rmtree(doc_path)
                    if os.path.exists(vector_store_path):
                        shutil.rmtree(vector_store_path)

                    st.success(f"Category '{selected_category_to_delete}' and all its data have been deleted.")
                    st.rerun()
                except Exception as e:
                    st.error(f"An error occurred while deleting the category: {e}")


# USER PAGE 

def user_page():
    """
    User-facing chatbot interface.
    """
    st.sidebar.title("Navigation")
    if st.sidebar.button("Logout"):
        st.session_state.authenticated = False
        st.session_state.role = None
        st.rerun()

    st.title("👉 📘 IMCC Student Information Hub")
    st.write("Select a topic and ask a question. I will find the answer from the official documents.")

    try:
        processed_topics = [d for d in os.listdir("vector_stores") if os.path.isdir(os.path.join("vector_stores", d))]
    except FileNotFoundError:
        processed_topics = []

    if not processed_topics:
        st.info("No topics have been processed by the admin yet. Please check back later.")
        return

    selected_topic = st.selectbox("Please select a topic of interest:", options=processed_topics)

    if selected_topic:
        # Load the vector store when a topic is selected
        if 'active_topic' not in st.session_state or st.session_state.active_topic != selected_topic:
            with st.spinner(f"Loading information for '{selected_topic}'..."):
                try:
                    embeddings = get_embeddings()
                    if embeddings:
                        vector_store_path = os.path.join("vector_stores", selected_topic)
                        st.session_state.vector_store = FAISS.load_local(
                            vector_store_path,
                            embeddings,
                            allow_dangerous_deserialization=True
                        )
                        st.session_state.active_topic = selected_topic
                        st.session_state.qa_messages = [] 
                        st.success(f"✅ Ready to answer questions about **{selected_topic}**.")
                except Exception as e:
                    st.error(f"Failed to load the topic. It might not be processed correctly. Error: {e}")
                    return

        st.markdown("---")
        st.header(f"Ask Questions About: {st.session_state.active_topic}")

        if "qa_messages" not in st.session_state:
            st.session_state.qa_messages = []

        for message in st.session_state.qa_messages:
            with st.chat_message(message["role"]):
                st.markdown(message["content"])

        if question := st.chat_input(f"Ask something about {st.session_state.active_topic}..."):
            st.session_state.qa_messages.append({"role": "user", "content": question})
            with st.chat_message("user"):
                st.markdown(question)

            with st.chat_message("assistant"):
                with st.spinner("Searching for the answer..."):
                    try:
                        llm = get_qa_llm()
                        if llm and 'vector_store' in st.session_state:
                            qa_chain = RetrievalQA.from_chain_type(
                                llm=llm,
                                chain_type="stuff",
                                retriever=st.session_state.vector_store.as_retriever(search_kwargs={"k": 3}),
                                chain_type_kwargs={"prompt": qa_prompt},
                                return_source_documents=True
                            )
                            response = qa_chain.invoke({"query": question})
                            answer = response.get("result", "No answer found.")
                            st.markdown(answer)

                            with st.expander("📄 View Sources"):
                                source_docs = response.get("source_documents", [])
                                if source_docs:
                                    for i, doc in enumerate(source_docs):
                                        st.info(f"**Source Chunk {i+1} (from page {doc.metadata.get('page', 'N/A')}):**\n\n{doc.page_content[:350]}...")
                                else:
                                    st.write("No source documents found.")

                            st.session_state.qa_messages.append({"role": "assistant", "content": answer})
                        else:
                            st.error("The language model or document index is not available.")
                    except Exception as e:
                        error_msg = f"An error occurred: {e}"
                        st.error(error_msg)
                        st.session_state.qa_messages.append({"role": "assistant", "content": error_msg})

# LOGIN & MAIN APP 

def login_page():
    """Displays the login page."""
    st.title("🔐 Login")
    st.write("Please enter your credentials to access the chatbot.")

    # Use a dictionary for credentials for easy management
    credentials = {
        "admin": {"password": "admin_password", "role": "admin"},
        "student": {"password": "student_password", "role": "user"}
    }

    with st.form("login_form"):
        username = st.text_input("Username").lower()
        password = st.text_input("Password", type="password")
        submitted = st.form_submit_button("Login")

        if submitted:
            user_data = credentials.get(username)
            if user_data and user_data["password"] == password:
                st.session_state.authenticated = True
                st.session_state.role = user_data["role"]
                st.rerun()
            else:
                st.error("Invalid username or password")

def main():
    """Main function to run the Streamlit app."""
    # --- Load and set API Key ---
    try:
        grok_api_key = st.secrets["grok_api_key"]
        # Set Groq API Key as an environment variable for LangChain components
        os.environ["GROQ_API_KEY"] = grok_api_key
    except (KeyError, FileNotFoundError):
        st.error("🚨 Groq API Key not found. Please add it to your Streamlit secrets.")
        st.stop()

    # Ensure required directories exist
    setup_directories()

    if 'authenticated' not in st.session_state:
        st.session_state.authenticated = False
        st.session_state.role = None

    if st.session_state.authenticated:
        if st.session_state.role == 'admin':
            admin_page()
        else: # role == 'user'
            user_page()
    else:
        login_page()

if __name__ == "__main__":
    main()