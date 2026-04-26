import asyncio
import os
from dotenv import load_dotenv
from agents.news_ingestion_agent import NewsIngestionAgent

load_dotenv()

async def test():
    agent = NewsIngestionAgent(
        groq_api_key=os.getenv("GROQ_API_KEY"),
        news_api_key=os.getenv("NEWS_API_KEY")
    )
    
    print("Testing NewsAPI fetch...")
    newsapi_results = await agent._fetch_newsapi()
    print(f"Found {len(newsapi_results)} articles from NewsAPI.")
    
    if newsapi_results:
        print(f"Sample: {newsapi_results[0]['headline']}")
        
    print("\nTesting GDELT fetch...")
    gdelt_results = await agent._fetch_gdelt()
    print(f"Found {len(gdelt_results)} articles from GDELT.")
    
    if gdelt_results:
        print(f"Sample: {gdelt_results[0]['headline']}")

    # Test full enrichment on one article
    if newsapi_results:
        print("\nTesting Trafilatura enrichment...")
        enriched = await agent._enrich_articles([newsapi_results[0]])
        if enriched:
            print(f"Enriched content length: {len(enriched[0]['full_content'])}")
            print(f"Snippet: {enriched[0]['full_content'][:200]}...")

if __name__ == "__main__":
    asyncio.run(test())
