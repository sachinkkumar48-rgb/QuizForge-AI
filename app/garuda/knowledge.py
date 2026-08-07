"""
GARUDA AI Knowledge Engine & RAG Abstraction Layer.

Implements KnowledgeDocument, KnowledgeChunk, ChunkingService interface,
EmbeddingService interface, VectorStore interface, Retriever interface, and Knowledge Exceptions.

Provides pure Python reference implementations (InMemoryVectorStore, SimpleRetriever) for zero-dependency RAG.

Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, or concrete vector DBs (ChromaDB/Pinecone/pgvector).
"""
import math
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, List, Optional

from app.garuda.domain import GarudaException


class KnowledgeEngineException(GarudaException):
    """Base exception for all Knowledge Engine errors."""

    def __init__(self, message: str, code: str = "KNOWLEDGE_ENGINE_ERROR"):
        super().__init__(message, code=code)


class DocumentNotFoundException(KnowledgeEngineException):
    """Raised when a specified document is not found in the Knowledge Engine."""

    def __init__(self, doc_id: str):
        super().__init__(f"KnowledgeDocument '{doc_id}' not found.", code="DOCUMENT_NOT_FOUND")


class EmbeddingServiceException(KnowledgeEngineException):
    """Raised when embedding generation fails."""

    def __init__(self, detail: str = ""):
        message = "Embedding service failure."
        if detail:
            message += f" Detail: {detail}"
        super().__init__(message, code="EMBEDDING_FAILURE")


class VectorStoreException(KnowledgeEngineException):
    """Raised when vector storage or query operations fail."""

    def __init__(self, detail: str = ""):
        message = "Vector store error."
        if detail:
            message += f" Detail: {detail}"
        super().__init__(message, code="VECTOR_STORE_ERROR")


@dataclass
class KnowledgeDocument:
    """Represents a source document (PDF, notes, PYQ text) indexed into GARUDA Knowledge Engine."""
    doc_id: str
    title: str
    content: str
    doc_type: str = "general"
    metadata: Dict = field(default_factory=dict)
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def get_content_length(self) -> int:
        return len(self.content) if self.content else 0


@dataclass
class KnowledgeChunk:
    """Represents an atomic text chunk and its embedding vector for RAG retrieval."""
    chunk_id: str
    doc_id: str
    text: str
    chunk_index: int
    embedding: Optional[List[float]] = None
    metadata: Dict = field(default_factory=dict)

    def has_embedding(self) -> bool:
        return bool(self.embedding and len(self.embedding) > 0)


class IChunkingService(ABC):
    """Abstract interface for splitting KnowledgeDocuments into chunks."""

    @abstractmethod
    def chunk_document(
        self, doc: KnowledgeDocument, chunk_size: int = 500, overlap: int = 50
    ) -> List[KnowledgeChunk]:
        """Splits a document into a sequence of KnowledgeChunks."""
        pass


class IEmbeddingService(ABC):
    """Abstract interface for generating vector embeddings."""

    @abstractmethod
    async def embed_text(self, text: str) -> List[float]:
        """Generates a vector embedding for a text string."""
        pass

    @abstractmethod
    async def embed_chunks(self, chunks: List[KnowledgeChunk]) -> List[KnowledgeChunk]:
        """Populates vector embeddings across a list of KnowledgeChunks."""
        pass


class IVectorStore(ABC):
    """Abstract interface for vector database operations (add, query, delete)."""

    @abstractmethod
    async def add_chunks(self, chunks: List[KnowledgeChunk]) -> bool:
        """Adds or updates KnowledgeChunks in the vector store."""
        pass

    @abstractmethod
    async def query_similar(self, query_embedding: List[float], top_k: int = 3) -> List[KnowledgeChunk]:
        """Retrieves top-K KnowledgeChunks closest to query_embedding."""
        pass

    @abstractmethod
    async def delete_doc(self, doc_id: str) -> bool:
        """Deletes all chunks belonging to doc_id."""
        pass


class IRetriever(ABC):
    """Abstract interface for RAG document retrieval."""

    @abstractmethod
    async def retrieve_relevant_chunks(self, query: str, top_k: int = 3) -> List[KnowledgeChunk]:
        """Retrieves relevant KnowledgeChunks for a natural language query."""
        pass


# ==============================================================================
# Pure Python Reference Implementations (Zero-Dependency)
# ==============================================================================

def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Computes cosine similarity between two vector lists in pure Python."""
    if not vec1 or not vec2 or len(vec1) != len(vec2):
        return 0.0

    dot_product = 0.0
    norm_a = 0.0
    norm_b = 0.0
    for a, b in zip(vec1, vec2):
        dot_product += a * b
        norm_a += a * a
        norm_b += b * b

    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0
    return dot_product / (math.sqrt(norm_a) * math.sqrt(norm_b))


class InMemoryVectorStore(IVectorStore):
    """Zero-dependency in-memory vector store using pure Python cosine similarity."""

    def __init__(self):
        self._chunks: Dict[str, KnowledgeChunk] = {}

    async def add_chunks(self, chunks: List[KnowledgeChunk]) -> bool:
        for chunk in chunks:
            if not chunk.has_embedding():
                raise VectorStoreException(f"Chunk '{chunk.chunk_id}' lacks embedding vector.")
            self._chunks[chunk.chunk_id] = chunk
        return True

    async def query_similar(self, query_embedding: List[float], top_k: int = 3) -> List[KnowledgeChunk]:
        if not query_embedding:
            return []

        query_norm = math.sqrt(sum(a * a for a in query_embedding))
        if query_norm == 0.0:
            return []

        scored_chunks = []
        for chunk in self._chunks.values():
            emb = chunk.embedding
            if emb and len(emb) == len(query_embedding):
                dot_product = 0.0
                norm_b = 0.0
                for a, b in zip(query_embedding, emb):
                    dot_product += a * b
                    norm_b += b * b
                if norm_b > 0.0:
                    score = dot_product / (query_norm * math.sqrt(norm_b))
                    scored_chunks.append((score, chunk))

        scored_chunks.sort(key=lambda x: x[0], reverse=True)
        return [c for score, c in scored_chunks[:top_k]]

    async def delete_doc(self, doc_id: str) -> bool:
        to_delete = [cid for cid, c in self._chunks.items() if c.doc_id == doc_id]
        for cid in to_delete:
            del self._chunks[cid]
        return bool(to_delete)

    def count(self) -> int:
        return len(self._chunks)


class SimpleRetriever(IRetriever):
    """Pure Python retriever combining an IEmbeddingService and an IVectorStore."""

    def __init__(self, embedding_service: IEmbeddingService, vector_store: IVectorStore):
        self.embedding_service = embedding_service
        self.vector_store = vector_store

    async def retrieve_relevant_chunks(self, query: str, top_k: int = 3) -> List[KnowledgeChunk]:
        if not query or not query.strip():
            return []
        query_embedding = await self.embedding_service.embed_text(query)
        return await self.vector_store.query_similar(query_embedding, top_k=top_k)
