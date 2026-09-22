---
name: rag-pipeline-architect
description: "Retrieval-Augmented Generation (RAG) architecture: hybrid retrieval (dense vector + BM25 sparse), semantic chunking, cross-encoder reranking, pgvector/Qdrant indexing, and context window optimization. Use when designing search or RAG systems."
---

# Retrieval-Augmented Generation (RAG) Architecture

Standards for high-precision, low-hallucination RAG knowledge retrieval and vector indexing systems.

## Core Rules

1. **Chunking & Preprocessing**:
   - Chunk by semantic boundaries (markdown headers, code functions, paragraphs) rather than arbitrary fixed token sizes.
   - Attach rich metadata to every chunk: source file path, section hierarchy, entity tags, and timestamp.
   - Maintain a sliding window with small token overlap (10–15%) to prevent context fragmentation across chunk splits.

2. **Hybrid Search Strategy**:
   - Combine dense vector embeddings (semantic similarity) with sparse keyword search (BM25 / Postgres Full-Text Search) using Reciprocal Rank Fusion (RRF).
   - Use dense search for conceptual questions and sparse search for exact symbol, ID, or acronym lookups.

3. **Reranking & Context Packing**:
   - Run a two-stage retrieval pipeline: retrieve Top-K (e.g. 25–50) candidates via hybrid search, then prune to Top-N (3–5) using a cross-encoder reranker (Cohere / BGE-Reranker).
   - Strip irrelevant metadata before packing chunks into the LLM context to minimize token waste.

4. **Vector Database Optimization**:
   - Use HNSW indexes for low-latency similarity queries; tune `m` and `ef_construction` for recall accuracy.
   - Enforce partition-based or tenant-based vector filtering before calculating cosine distance to maintain sub-10ms query times.
