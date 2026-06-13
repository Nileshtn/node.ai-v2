from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class GraphConnection:
    source_node_index: int
    source_socket: str
    target_node_index: int
    target_socket: str
