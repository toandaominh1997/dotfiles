from typing import List, Union, Generator, Iterator
import os 


class Pipeline:
    def __init__(self):
        self.index = 0

    async def on_startup(self):
        # This function is called when the server is started.
        pass

    async def on_shutdown(self):
        # This function is called when the server is stopped.
        pass

    def pipe(
        self, user_message: str, model_id: str, messages: List[dict], body: dict
    ) -> Union[str, Generator, Iterator]:
        self.index += 1
        return f"Index at {self.index}"
