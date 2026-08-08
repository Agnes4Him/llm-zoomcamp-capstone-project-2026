import json
import sys

import requests

API_URL_LOCAL = "http://localhost/api"
API_URL_CLOUD_K8S = "http://18.175.239.80/api"

API_URL = f"{API_URL_CLOUD_K8S}/monitoring"

def fetch_monitoring(limit: int) -> dict:
    try:
        response = requests.get(f"{API_URL}?limit={limit}", timeout=20)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as exc:
        raise RuntimeError(f"Failed to fetch monitoring data: {exc}") from exc


def main() -> None:
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 10

    try:
        payload = fetch_monitoring(limit)
    except Exception as exc:
        print(str(exc))
        raise SystemExit(1) from exc

    print(json.dumps(payload, indent=2, default=str))


if __name__ == "__main__":
    main()
