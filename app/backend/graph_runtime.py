from __future__ import annotations

from typing import Any

from PySide6.QtCore import QObject, Slot

from backend.graph_evaluator import GraphEvaluator


class GraphRuntime(QObject):
    """QML-facing calculation backend for the visual node graph."""

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._evaluator = GraphEvaluator()

    @Slot("QVariant", "QVariant", result="QVariant")
    def evaluate(self, nodes: Any, connections: Any) -> dict[str, Any]:
        return self._evaluator.evaluate(nodes, connections)
