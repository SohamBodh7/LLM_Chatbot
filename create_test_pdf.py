#!/usr/bin/env python3
"""
Create a sample test PDF for chatbot testing
"""

from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

def create_test_pdf():
    """Create a sample test PDF with various content types"""
    
    # Create the PDF document
    doc = SimpleDocTemplate("test_document.pdf", pagesize=letter)
    styles = getSampleStyleSheet()
    
    # Create custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=16,
        spaceAfter=30,
        alignment=1  # Center alignment
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=14,
        spaceAfter=12,
        spaceBefore=12
    )
    
    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['Normal'],
        fontSize=11,
        spaceAfter=6,
        leading=14
    )
    
    # Story to hold the content
    story = []
    
    # Title
    story.append(Paragraph("Sample Research Document for Chatbot Testing", title_style))
    story.append(Spacer(1, 20))
    
    # Abstract
    story.append(Paragraph("Abstract", heading_style))
    story.append(Paragraph("""
    This document serves as a comprehensive test case for evaluating the capabilities 
    of document-based chatbot systems. It contains various types of content including 
    technical information, research findings, and analytical data that can be used to 
    assess the chatbot's ability to process, understand, and respond to user queries 
    about document content.
    """, body_style))
    story.append(Spacer(1, 12))
    
    # Introduction
    story.append(Paragraph("1. Introduction", heading_style))
    story.append(Paragraph("""
    Document-based chatbots represent a significant advancement in natural language 
    processing and information retrieval systems. These systems combine the power of 
    large language models with sophisticated document processing capabilities to provide 
    users with intelligent, context-aware responses based on specific document content.
    """, body_style))
    story.append(Paragraph("""
    The primary objective of this research is to evaluate the effectiveness of 
    document-based chatbot systems in processing various types of content, including 
    technical documents, research papers, and analytical reports. The study focuses 
    on assessing accuracy, response quality, and user satisfaction metrics.
    """, body_style))
    story.append(Spacer(1, 12))
    
    # Methodology
    story.append(Paragraph("2. Methodology", heading_style))
    story.append(Paragraph("""
    The research methodology employed a mixed-methods approach combining quantitative 
    and qualitative analysis. The study involved testing the chatbot system with a 
    diverse set of documents including technical specifications, research papers, 
    and business reports.
    """, body_style))
    story.append(Paragraph("""
    Key metrics evaluated included:
    • Response accuracy and relevance
    • Processing speed and efficiency
    • User satisfaction scores
    • Error handling capabilities
    • Context understanding and retention
    """, body_style))
    story.append(Spacer(1, 12))
    
    # Results
    story.append(Paragraph("3. Results and Findings", heading_style))
    story.append(Paragraph("""
    The experimental results demonstrated significant improvements in document 
    processing capabilities when compared to traditional information retrieval systems. 
    The chatbot achieved an average accuracy rate of 87% across all test scenarios, 
    with particularly strong performance in technical document analysis.
    """, body_style))
    story.append(Paragraph("""
    Key findings include:
    • Enhanced context understanding through vector embeddings
    • Improved response relevance through semantic search
    • Reduced processing time by 40% compared to manual analysis
    • High user satisfaction scores averaging 4.2/5.0
    """, body_style))
    story.append(Spacer(1, 12))
    
    # Technical Specifications
    story.append(Paragraph("4. Technical Specifications", heading_style))
    story.append(Paragraph("""
    The chatbot system utilizes advanced natural language processing techniques 
    including transformer-based models, vector embeddings, and semantic search 
    algorithms. The system architecture consists of several key components:
    """, body_style))
    story.append(Paragraph("""
    • Document Processing Engine: Handles PDF parsing and text extraction
    • Vector Database: Stores document embeddings for efficient retrieval
    • Language Model: Generates contextual responses based on document content
    • User Interface: Provides intuitive interaction capabilities
    • API Integration: Enables seamless connectivity with external services
    """, body_style))
    story.append(Spacer(1, 12))
    
    # Conclusions
    story.append(Paragraph("5. Conclusions", heading_style))
    story.append(Paragraph("""
    The research demonstrates that document-based chatbot systems represent a 
    viable solution for intelligent document analysis and information retrieval. 
    The combination of advanced NLP techniques with sophisticated document 
    processing capabilities provides users with powerful tools for extracting 
    insights from complex documents.
    """, body_style))
    story.append(Paragraph("""
    Future research directions include expanding the system's capabilities to 
    handle multimedia content, improving multilingual support, and developing 
    more sophisticated reasoning capabilities for complex analytical tasks.
    """, body_style))
    story.append(Spacer(1, 12))
    
    # References
    story.append(Paragraph("6. References", heading_style))
    story.append(Paragraph("""
    1. Smith, J. et al. (2023). "Advanced Document Processing Systems." 
       Journal of Information Technology, 45(2), 123-145.
    
    2. Johnson, A. (2023). "Natural Language Processing in Document Analysis." 
       Computer Science Review, 18(4), 234-256.
    
    3. Brown, M. (2023). "Vector Embeddings for Information Retrieval." 
       AI Research Quarterly, 12(1), 67-89.
    """, body_style))
    
    # Build the PDF
    doc.build(story)
    print("✅ Test PDF created successfully: test_document.pdf")

if __name__ == "__main__":
    create_test_pdf()

