-- Create a table to store your langchain_documents
create table
  langchain_documents (
    id uuid primary key,
    content text, -- corresponds to Document.pageContent
    metadata jsonb, -- corresponds to Document.metadata
    embedding vector (384) -- 1536 works for OpenAI embeddings, change if needed 384 for thenlper/gte-small
  );

-- Create a function to search for langchain_documents
create function match_documents (
  query_embedding vector (384),
  filter jsonb default '{}'
) returns table (
  id uuid,
  content text,
  metadata jsonb,
  similarity float
) language plpgsql as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (langchain_documents.embedding <=> query_embedding) as similarity
  from langchain_documents
  where metadata @> filter
  order by langchain_documents.embedding <=> query_embedding;
end;
$$;

CREATE OR REPLACE FUNCTION
  match_langchain_documents_mmr (query_embedding vector (384)) RETURNS TABLE (
    id uuid,
    content text,
    metadata jsonb,
    embedding vector (384),
    similarity float
  ) LANGUAGE plpgsql AS $$
# variable_conflict use_column
BEGIN
    RETURN query
    SELECT
        id,
        content,
        metadata,
        embedding,
        1 -(langchain_documents.embedding <=> query_embedding) AS similarity
    FROM
        langchain_documents
    ORDER BY
        langchain_documents.embedding <=> query_embedding;
END;
$$;