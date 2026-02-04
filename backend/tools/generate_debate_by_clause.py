import json
import os
import time
from pathlib import Path

from debate_agents import DebateAgents
from models import Clause

try:
    from openai import RateLimitError
except Exception:  # pragma: no cover
    RateLimitError = Exception


def _build_clauses(risky_items):
    clauses = []
    for c in risky_items:
        clauses.append(
            Clause(
                id=c.get('id') or '',
                article_num=c.get('article_num') or '',
                title=c.get('title') or '',
                content=c.get('content') or '',
                risk_level=None,
                risk_reason=c.get('risk_reason'),
                related_precedents=c.get('related_precedents') or [],
                related_laws=c.get('related_laws') or [],
                highlight_sentences=c.get('highlight_sentences') or [],
                highlight_keywords=c.get('highlight_keywords') or [],
            )
        )
    return clauses


def main():
    analysis_path = Path('analysis_result.json')
    if not analysis_path.exists():
        raise SystemExit('analysis_result.json not found')

    data = json.loads(analysis_path.read_text(encoding='utf-8'))
    raw_text = data.get('raw_text') or ''
    risky = data.get('risky_clauses') or []

    max_clauses = int(os.getenv('DEBATE_MAX_CLAUSES', '0'))
    if max_clauses > 0:
        risky = risky[:max_clauses]

    clauses = _build_clauses(risky)
    if not clauses:
        raise SystemExit('no risky clauses')

    batch_size = int(os.getenv('DEBATE_BATCH_SIZE', '2'))
    sleep_sec = float(os.getenv('DEBATE_SLEEP_SEC', '2'))
    retry_sleep = float(os.getenv('DEBATE_RETRY_SLEEP_SEC', '5'))

    agents = DebateAgents()
    contract_type = agents.detect_contract_type(raw_text)

    results = []
    for i, clause in enumerate(clauses, start=1):
        while True:
            try:
                transcript = agents.run(
                    [clause],
                    raw_text=raw_text,
                    contract_type=contract_type,
                )
                results.append(
                    {
                        'clause_id': clause.id,
                        'article_num': clause.article_num,
                        'title': clause.title,
                        'transcript': transcript,
                    }
                )
                break
            except RateLimitError:
                time.sleep(retry_sleep)
            except Exception as exc:  # keep moving; store error marker
                results.append(
                    {
                        'clause_id': clause.id,
                        'article_num': clause.article_num,
                        'title': clause.title,
                        'transcript': [
                            {
                                'speaker': 'system',
                                'content': f'error: {exc}',
                            }
                        ],
                    }
                )
                break

        # periodic save
        data['debate_by_clause'] = results
        data['contract_type'] = contract_type
        analysis_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2),
            encoding='utf-8',
        )

        if i % batch_size == 0:
            time.sleep(sleep_sec)

    print('UPDATED', analysis_path)


if __name__ == '__main__':
    main()
