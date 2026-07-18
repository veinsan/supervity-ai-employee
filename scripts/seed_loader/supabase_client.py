"""Minimal Supabase (PostgREST) REST client for the reseeding utility (TASKS.md 3.1).

Drop-in counterpart to airtable_client.py, covering the same call shapes loader.py/
seed_policy_config.py already use (upsert_batch, delete_all) — same retry-profile contract
(config/policy_config.json's `retry` block, ARCHITECTURE.md §7 "never hardcoded"), different
wire format because PostgREST's upsert/auth/pagination semantics differ from Airtable's:

- Auth needs BOTH the `apikey` header and `Authorization: Bearer` (Airtable only needed the
  latter) — Supabase rejects a request missing either.
- Upsert is header-driven (`Prefer: resolution=merge-duplicates` + `?on_conflict=<key_field>`
  query param), not a body field like Airtable's `performUpsert`.
- No documented per-request record cap or per-second rate limit at this project's scale, so the
  10-row batching and the fixed inter-request sleep Airtable needed are dropped; chunking is kept
  only as a defensive cap against one oversized payload, not to dodge a rate limit.
- `delete_all` is a single DELETE with a match-everything filter (PostgREST rejects a filter-less
  DELETE outright — verified against the live project, see the method's docstring) rather than
  Airtable's list-ids-then-batch-delete dance; there's no synthetic per-record ID to collect first.

Only covers the tables actually migrated so far: Workers, Manager_Directory, policy_config
(see config/supabase_schema.sql). Onboarding_Tasks, Provisioning_Integration, Peakon_Engagement,
and "Cases & Audit Log" still live in Airtable — loader.py is not yet wired to route per-table
between this client and airtable_client.py; that's the next step, not done here.
"""

from __future__ import annotations

import time
from typing import Sequence
from urllib.parse import quote

import requests

BATCH_SIZE = 500  # defensive cap on one request's payload size, not a rate-limit workaround.


class SupabaseError(RuntimeError):
    pass


def _chunks(items, size):
    for i in range(0, len(items), size):
        yield items[i : i + size]


class SupabaseClient:
    def __init__(self, url: str, key: str, retry: dict | None = None, session=None):
        self.rest_root = f"{url.rstrip('/')}/rest/v1"
        self.retry = retry or {"max_attempts": 3, "backoff_seconds": [5, 20, 60]}
        self.session = session or requests.Session()
        self.session.headers.update(
            {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"}
        )

    def _url(self, table: str) -> str:
        return f"{self.rest_root}/{quote(table, safe='')}"

    def _request(self, method: str, url: str, **kwargs) -> object:
        backoffs = self.retry["backoff_seconds"]
        attempts = self.retry["max_attempts"]
        last_error = None
        for attempt in range(attempts):
            try:
                resp = self.session.request(method, url, timeout=30, **kwargs)
            except requests.RequestException as exc:
                last_error = str(exc)
            else:
                if resp.status_code < 300:
                    return resp.json() if resp.content else None
                if resp.status_code == 429 or resp.status_code >= 500:
                    last_error = f"HTTP {resp.status_code}: {resp.text[:300]}"
                else:
                    raise SupabaseError(f"HTTP {resp.status_code}: {self._error_detail(resp)}")
            if attempt < attempts - 1:
                time.sleep(backoffs[min(attempt, len(backoffs) - 1)])
        raise SupabaseError(f"exhausted {attempts} attempts against {url}: {last_error}")

    @staticmethod
    def _error_detail(resp) -> str:
        try:
            body = resp.json()
        except ValueError:
            return resp.text[:500]
        return body.get("message") or body.get("hint") or str(body)[:500]

    def upsert_batch(self, table: str, key_field: str, field_rows: Sequence[dict]) -> list:
        """Upsert `field_rows` (each a flat {column: value} dict) into `table`, merging on the
        UNIQUE/PRIMARY KEY constraint over `key_field` (must exist — see config/supabase_schema.sql).
        Returns the rows Supabase wrote back."""
        written = []
        url = self._url(table)
        for chunk in _chunks(list(field_rows), BATCH_SIZE):
            if not chunk:
                continue
            result = self._request(
                "POST",
                url,
                params={"on_conflict": key_field},
                headers={"Prefer": "resolution=merge-duplicates,return=representation"},
                json=chunk,
            )
            written.extend(result or [])
        return written

    def delete_all(self, table: str, key_field: str) -> int:
        """Delete every row in `table`. Mirrors airtable_client.AirtableClient.delete_all's role
        (used only by --reset, never against a source table) but needs no ID round-trip first —
        PostgREST rejects a filter-less DELETE ("DELETE requires a WHERE clause", verified against
        the live project), so `key_field=not.is.null` is used as an always-true match-everything
        filter instead. `key_field` must be a NOT NULL column (every table here has one: its
        primary key)."""
        result = self._request(
            "DELETE",
            self._url(table),
            params={key_field: "not.is.null"},
            headers={"Prefer": "return=representation"},
        )
        return len(result or [])
