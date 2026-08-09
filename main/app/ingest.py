from langchain_community.document_loaders import (
    DirectoryLoader,
    TextLoader
)

from langchain_text_splitters import (
    RecursiveCharacterTextSplitter
)

from app.rag_helper import (
    create_vectorstore
)

def load_knowledge_base():
    """
    Load the knowledge base into Pinecone
    """

    print("Loading knowledge base documents")

    try:
        loader = DirectoryLoader(
            "knowledge-base",
            glob="**/*.txt",
            loader_cls=TextLoader
        )

        documents = loader.load()

        print(
            "Loaded %s documents from knowledge base",
            len(documents)
        )

        splitter = RecursiveCharacterTextSplitter(
            chunk_size=800,
            chunk_overlap=150
        )

        chunks = splitter.split_documents(documents)

        print(
            "Created %s document chunks",
            len(chunks)
        )

        return chunks

    except Exception:
        print("Failed to load knowledge base")
        raise

def add_documents_to_vectorstore():
    """
    Add documents to the vectorstore
    """

    print("Adding documents to vectorstore")

    try:
        vectorstore = create_vectorstore()
        chunks = load_knowledge_base()

        vectorstore.add_documents(
            chunks
        )

        print(
            "Successfully added %s documents to vectorstore",
            len(chunks)
        )

    except Exception:
        print(
            "Failed to add documents to vectorstore"
        )
        raise

if __name__ == "__main__":
    add_documents_to_vectorstore()