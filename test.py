from typing import List, Union, Generator, Iterator
import os 
from langchain_core.prompts import ChatPromptTemplate
from langchain_ollama.llms import OllamaLLM

class Pipeline:
    def __init__(self):
        self.index = 0

    async def on_startup(self):
        # This function is called when the server is started.
        template = """Question: {question}

Answer: Let's think step by step."""

        prompt = ChatPromptTemplate.from_template(template)
        
        model = OllamaLLM(model="llama3.2")
        
        self.chain = prompt | model
        pass

    async def on_shutdown(self):
        # This function is called when the server is stopped.
        pass

    def pipe(
        self, user_message: str, model_id: str, messages: List[dict], body: dict
    ) -> Union[str, Generator, Iterator]:
        self.index += 1
        answer = chain.invoke({"question": user_message})
        return answer
