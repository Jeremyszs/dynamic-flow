import os
import sqlite3
import time
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Dict, Optional

@dataclass
class AgentStatus:
    name: str
    model: str
    is_active: bool
    last_seen_sec: Optional[float]
    today_tokens: int
    reasoning_tokens: int
    latest_task: str
    latest_tool: Optional[str] = None
    time_ago_str: str = "offline"

@dataclass
class FleetSnapshot:
    state: str  # "IDLE", "BUSY"
    active_agents: List[str]
    total_tokens_today: int
    total_reasoning_today: int
    active_tool: Optional[str] = None
    agents: Dict[str, AgentStatus] = field(default_factory=dict)

class FleetDataService:
    def __init__(self):
        self.hermes_home = Path(os.path.expandvars(r"%LOCALAPPDATA%\hermes"))
        self.profiles_dir = self.hermes_home / "profiles"

    def fetch_fleet_snapshot(self) -> FleetSnapshot:
        now = time.time()
        agents = {}
        active_agents = []
        total_tokens = 0
        total_reasoning = 0
        active_tool = None

        default_db = self.hermes_home / "state.db"
        if default_db.exists():
            status = self._read_profile_status("orchestrator", "default-combo", default_db, now)
            agents["orchestrator"] = status
            total_tokens += status.today_tokens
            total_reasoning += status.reasoning_tokens
            if status.is_active:
                active_agents.append("orchestrator")
                if status.latest_tool:
                    active_tool = status.latest_tool

        if self.profiles_dir.exists():
            for prof_dir in sorted(self.profiles_dir.iterdir()):
                if prof_dir.is_dir():
                    name = prof_dir.name
                    db_path = prof_dir / "state.db"
                    status = self._read_profile_status(name, "9router", db_path, now)
                    agents[name] = status
                    total_tokens += status.today_tokens
                    total_reasoning += status.reasoning_tokens
                    if status.is_active:
                        active_agents.append(name)
                        if status.latest_tool and not active_tool:
                            active_tool = status.latest_tool

        fleet_state = "BUSY" if active_agents else "IDLE"
        return FleetSnapshot(
            state=fleet_state,
            active_agents=active_agents,
            total_tokens_today=total_tokens,
            total_reasoning_today=total_reasoning,
            active_tool=active_tool,
            agents=agents
        )

    def _read_profile_status(self, name: str, fallback_model: str, db_path: Path, now: float) -> AgentStatus:
        if not db_path.exists():
            return AgentStatus(
                name=name, model=fallback_model, is_active=False,
                last_seen_sec=None, today_tokens=0, reasoning_tokens=0,
                latest_task="Offline", latest_tool=None, time_ago_str="offline"
            )

        try:
            uri = f"file:{db_path.as_posix()}?mode=ro"
            with sqlite3.connect(uri, uri=True, timeout=1.0) as conn:
                conn.row_factory = sqlite3.Row
                c = conn.cursor()
                c.execute("""
                    SELECT id, title, started_at, last_activity_at, model,
                           COALESCE(input_tokens, 0) + COALESCE(output_tokens, 0) + COALESCE(reasoning_tokens, 0) AS tokens,
                           COALESCE(reasoning_tokens, 0) AS reasoning
                    FROM sessions
                    ORDER BY started_at DESC
                    LIMIT 1
                """)
                row = c.fetchone()
                if not row:
                    return AgentStatus(
                        name=name, model=fallback_model, is_active=False,
                        last_seen_sec=None, today_tokens=0, reasoning_tokens=0,
                        latest_task="Idle", latest_tool=None, time_ago_str="never"
                    )

                session_id = row["id"]
                last_act = row["last_activity_at"] or row["started_at"] or 0
                sec_ago = max(0.0, now - last_act) if last_act > 0 else 999999.0
                is_active = sec_ago < 90.0

                if sec_ago < 10:
                    time_ago_str = "now"
                elif sec_ago < 60:
                    time_ago_str = f"{int(sec_ago)}s ago"
                elif sec_ago < 3600:
                    time_ago_str = f"{int(sec_ago // 60)}m ago"
                elif sec_ago < 86400:
                    time_ago_str = f"{int(sec_ago // 3600)}h ago"
                else:
                    time_ago_str = f"{int(sec_ago // 86400)}d ago"

                latest_tool = None
                try:
                    c.execute("""
                        SELECT tool_name FROM messages
                        WHERE session_id = ? AND role = 'tool' AND tool_name IS NOT NULL
                        ORDER BY id DESC LIMIT 1
                    """, (session_id,))
                    t_row = c.fetchone()
                    if t_row and t_row["tool_name"]:
                        latest_tool = t_row["tool_name"]
                except Exception:
                    pass

                today_start = now - (now % 86400)
                c.execute("""
                    SELECT SUM(COALESCE(input_tokens, 0) + COALESCE(output_tokens, 0) + COALESCE(reasoning_tokens, 0)) AS total,
                           SUM(COALESCE(reasoning_tokens, 0)) AS reasoning_total
                    FROM sessions
                    WHERE started_at >= ?
                """, (today_start,))
                sum_row = c.fetchone()
                today_tokens = sum_row["total"] if sum_row and sum_row["total"] else 0
                today_reasoning = sum_row["reasoning_total"] if sum_row and sum_row["reasoning_total"] else 0

                resolved_model = row["model"] or fallback_model
                if "/" in resolved_model:
                    resolved_model = resolved_model.split("/")[-1]

                return AgentStatus(
                    name=name,
                    model=resolved_model,
                    is_active=is_active,
                    last_seen_sec=sec_ago,
                    today_tokens=today_tokens,
                    reasoning_tokens=today_reasoning,
                    latest_task=row["title"] or "Active",
                    latest_tool=latest_tool,
                    time_ago_str=time_ago_str
                )
        except Exception:
            return AgentStatus(
                name=name, model=fallback_model, is_active=False,
                last_seen_sec=None, today_tokens=0, reasoning_tokens=0,
                latest_task="Standby", latest_tool=None, time_ago_str="standby"
            )
