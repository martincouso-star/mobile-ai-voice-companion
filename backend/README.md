# Voice companion API

FastAPI service used by the Flutter app. See the repository README for architecture, configuration, and deployment.

Local run from this directory:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

`GET /health` returns the active provider. `POST /chat` continues a session. With `LLM_PROVIDER` unset, replies come from the deterministic mock provider.
