#!/bin/bash
curl -X 'POST' \
  '<your-azureml-endpoint>v1/chat/completions' \
  -H 'accept: application/json' \
  -H 'azureml-model-deployment: <deployment-name>' \
  -H 'Authorization: Bearer <your-azureml-endpoint-token>' \
  -H 'Content-Type: application/json' \
  -d '{
  "messages": [
    {
      "content": "You are a polite and respectful chatbot helping people plan a vacation.",
      "role": "system"
    },
    {
      "content": "What should I do for a 4 day vacation in Spain?",
      "role": "user"
    }
  ],
  "model": "meta/llama3-8b-instruct",
  "max_tokens": 500,
  "top_p": 1,
  "n": 1,
  "stream": false,
  "stop": "\n",
  "frequency_penalty": 0.0
}'
