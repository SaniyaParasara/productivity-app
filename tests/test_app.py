import json
from app import app

def test_healthz_ok():
    client = app.test_client()
    res = client.get("/healthz")
    assert res.status_code == 200
    data = json.loads(res.data.decode())
    assert data.get("status") == "ok"
