import asyncio
import sys
import os

# Add the current directory to sys.path so we can import agents
sys.path.append(os.getcwd())

from agents.rss_feed_fetcher import RSSFeedFetcher

async def main():
    fetcher = RSSFeedFetcher()
    print("Fetching real news from RSS feeds...")
    print("(No API key needed)\n")
    
    articles = await fetcher.fetch_all_feeds()
    articles = fetcher.deduplicate(articles)
    
    print(f"Found {len(articles)} relevant disaster articles\n")
    
    for i, article in enumerate(articles, 1):
        print(f"Article {i}:")
        print(f"  Source: {article['display_name']} (trust: {article['trust_weight']})")
        print(f"  Headline: {article['headline'][:80]}...")
        print(f"  Location: {article['location']}")
        print(f"  Disaster: {article['disaster_type']}")
        print(f"  Severity: {article['severity']}")
        print(f"  URL: {article['url']}")
        print("-" * 40)
    
    if not articles:
        print("No disaster articles found right now.")
        print("This is normal — Mumbai/Maharashtra may not have active alerts.")
        print("The system will use demo scenarios in this case.")

if __name__ == "__main__":
    asyncio.run(main())
