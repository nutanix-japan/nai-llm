# nai-llm

Clone this repo to your github

```bash
git clone https://github.com/_your_git_handle/nai-llm.git
```

Create python virtual env and install requirements

```bash
cd nai-llm/
python3 -m venv .venv
pip install -r requirements.txt
```

Run your local mkdocs server to serve up the pages

```
source .venv/bin/activate

mkdocs serve

mkdocs serve --livereload # for live reloads

mkdocs serve --livereload -o -a localhost:9011   # use a different port (other than 8000)
```

The changes you make will be visible as you save the md files.

