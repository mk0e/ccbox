Requirements for an AI News Collector:

- I want to have an AI News collector which is autonomously scrapes a set of configurable sites on a daily basis in the internet and collects news articles from them
- I want to have some kind of editor functionality where I can press a button and a draft for the newsletter is being generated, I want to be able to edit the newsletter
- the draft should include the top 10 news articles which have been collected
- each article should be scored on relevance based on a configurable set of topics by an LLM
- the LLM to be integrated is anthropic haiku-4.5 using a custom endpoint and api key, please use litellm for this