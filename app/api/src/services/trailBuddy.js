import { DefaultAzureCredential } from '@azure/identity';
import { SearchClient } from '@azure/search-documents';
import OpenAI from 'openai';

const credential = new DefaultAzureCredential();

const searchClient = new SearchClient(
  process.env.AZURE_SEARCH_ENDPOINT,
  'nordlux-catalog',
  credential
);

const openaiClient = new OpenAI({
  baseURL: `${process.env.AZURE_OPENAI_ENDPOINT}openai`,
  apiKey: 'unused',
  defaultHeaders: { 'api-key': 'managed-identity' }
});

export async function trailBuddyChat(userMessage) {
  // Step 1: Search for relevant products
  const searchResults = await searchClient.search(userMessage, {
    top: 3,
    queryType: 'semantic',
    semanticSearchOptions: { configurationName: 'semantic-config' }
  });

  let context = '';
  for await (const result of searchResults.results) {
    context += result.document.content + '\n\n';
  }

  // Step 2: Generate response with OpenAI
  const response = await openaiClient.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: `You are Trail Buddy, Nordlux Outfitters' friendly AI product advisor.
Answer questions about Nordlux products using only the catalog information provided.
If you cannot find the answer in the catalog, say so honestly.
Keep answers concise and helpful. Always mention product codes and prices when relevant.

Catalog context:
${context}`
      },
      { role: 'user', content: userMessage }
    ],
    max_tokens: 500,
    temperature: 0.7
  });

  return response.choices[0].message.content;
}
