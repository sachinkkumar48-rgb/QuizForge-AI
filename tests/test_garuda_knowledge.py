"""
Unit tests for GARUDA AI Knowledge Engine (KnowledgeDocument, KnowledgeChunk, InMemoryVectorStore, SimpleRetriever).
"""
import pytest
from typing import List
from app.garuda.knowledge import (
    DocumentNotFoundException,
    EmbeddingServiceException,
    IEmbeddingService,
    InMemoryVectorStore,
    KnowledgeChunk,
    KnowledgeDocument,
    SimpleRetriever,
    VectorStoreException,
    cosine_similarity,
)


class MockEmbeddingService(IEmbeddingService):
    async def embed_text(self, text: str) -> List[float]:
        # Simple deterministic 3D embedding mock based on string length & presence of keywords
        val1 = float(len(text)) / 100.0
        val2 = 1.0 if "polity" in text.lower() else 0.0
        val3 = 1.0 if "history" in text.lower() else 0.0
        return [val1, val2, val3]

    async def embed_chunks(self, chunks: List[KnowledgeChunk]) -> List[KnowledgeChunk]:
        for c in chunks:
            c.embedding = await self.embed_text(c.text)
        return chunks


def test_knowledge_document_and_chunk_entities():
    doc = KnowledgeDocument(doc_id="doc1", title="Polity Notes", content="Article 14 guarantees equality before law.")
    assert doc.doc_id == "doc1"
    assert doc.title == "Polity Notes"
    assert doc.get_content_length() == 42

    chunk = KnowledgeChunk(chunk_id="c1", doc_id="doc1", text="Article 14", chunk_index=0)
    assert chunk.has_embedding() is False
    chunk.embedding = [0.1, 0.2, 0.3]
    assert chunk.has_embedding() is True


def test_cosine_similarity_math():
    v1 = [1.0, 0.0, 0.0]
    v2 = [1.0, 0.0, 0.0]
    v3 = [0.0, 1.0, 0.0]

    assert cosine_similarity(v1, v2) == 1.0
    assert cosine_similarity(v1, v3) == 0.0
    assert cosine_similarity([], [1.0]) == 0.0


@pytest.mark.anyio
async def test_in_memory_vector_store_operations():
    store = InMemoryVectorStore()
    assert store.count() == 0

    c1 = KnowledgeChunk(chunk_id="c1", doc_id="d1", text="Indian Polity Article 14", chunk_index=0, embedding=[1.0, 1.0, 0.0])
    c2 = KnowledgeChunk(chunk_id="c2", doc_id="d1", text="Modern History 1857 Revolt", chunk_index=1, embedding=[0.1, 0.0, 1.0])
    c3 = KnowledgeChunk(chunk_id="c3", doc_id="d2", text="Geography Monsoon", chunk_index=0, embedding=[0.0, 0.0, 0.5])

    await store.add_chunks([c1, c2, c3])
    assert store.count() == 3

    # Query for Polity [1.0, 1.0, 0.0]
    results = await store.query_similar([1.0, 1.0, 0.0], top_k=2)
    assert len(results) == 2
    assert results[0].chunk_id == "c1"

    # Delete doc d1
    deleted = await store.delete_doc("d1")
    assert deleted is True
    assert store.count() == 1


@pytest.mark.anyio
async def test_vector_store_missing_embedding_raises_exception():
    store = InMemoryVectorStore()
    chunk_no_emb = KnowledgeChunk(chunk_id="c_bad", doc_id="d1", text="No vector", chunk_index=0)

    with pytest.raises(VectorStoreException) as exc_info:
        await store.add_chunks([chunk_no_emb])
    assert exc_info.value.code == "VECTOR_STORE_ERROR"


@pytest.mark.anyio
async def test_simple_retriever_flow():
    embed_svc = MockEmbeddingService()
    vector_store = InMemoryVectorStore()

    c1 = KnowledgeChunk(chunk_id="c1", doc_id="d1", text="Polity Preamble", chunk_index=0)
    c2 = KnowledgeChunk(chunk_id="c2", doc_id="d1", text="History Revolt", chunk_index=1)
    embedded_chunks = await embed_svc.embed_chunks([c1, c2])
    await vector_store.add_chunks(embedded_chunks)

    retriever = SimpleRetriever(embedding_service=embed_svc, vector_store=vector_store)
    results = await retriever.retrieve_relevant_chunks("Polity question", top_k=1)

    assert len(results) == 1
    assert results[0].chunk_id == "c1"


def test_knowledge_exceptions():
    doc_exc = DocumentNotFoundException("d999")
    assert doc_exc.code == "DOCUMENT_NOT_FOUND"
    assert "d999" in str(doc_exc)

    emb_exc = EmbeddingServiceException("Rate limit")
    assert emb_exc.code == "EMBEDDING_FAILURE"
    assert "Rate limit" in str(emb_exc)
