from __future__ import annotations

from typing import Any

from backend.graph_connection import GraphConnection
from backend.graph_conditions import evaluate_condition_node
from backend.graph_generators import evaluate_generator
from backend.graph_operations import (
    apply_binary_operation,
    as_list,
    coerce_node_value,
    display_value,
)
from backend.graph_types import (
    CONDITION_NODE_TYPES,
    GENERATOR_NODE_TYPES,
    MATH_NODE_TYPES,
    VALUE_NODE_TYPES,
)


class GraphEvaluator:
    """Evaluates node graphs and produces lookup display values."""

    def evaluate(self, nodes: Any, connections: Any) -> dict[str, Any]:
        context = _EvaluationContext(nodes, connections)
        return context.run()


class _EvaluationContext:
    def __init__(self, nodes: Any, connections: Any) -> None:
        self.nodes = as_list(nodes)
        self.connections = self._parse_connections(connections)
        self.input_sources = {
            (connection.target_node_index, connection.target_socket): connection
            for connection in self.connections
        }
        self.cache: dict[tuple[int, str], Any] = {}
        self.errors: list[str] = []

    def run(self) -> dict[str, Any]:
        lookup_values = self._collect_lookup_values()

        if self.errors:
            return {
                "ok": False,
                "message": self.errors[0],
                "lookupValues": lookup_values,
            }

        return {
            "ok": True,
            "message": "Graph computed",
            "lookupValues": lookup_values,
        }

    def _parse_connections(self, connections: Any) -> list[GraphConnection]:
        return [
            GraphConnection(
                source_node_index=int(connection.get("sourceNodeIndex", -1)),
                source_socket=str(connection.get("sourceSocket", "")),
                target_node_index=int(connection.get("targetNodeIndex", -1)),
                target_socket=str(connection.get("targetSocket", "")),
            )
            for connection in as_list(connections)
            if isinstance(connection, dict)
        ]

    def _collect_lookup_values(self) -> dict[str, str]:
        lookup_values: dict[str, str] = {}

        for node_index, node in enumerate(self.nodes):
            if str(node.get("type", "")) != "Lookup":
                continue

            connection = self.input_sources.get((node_index, "value"))

            if not connection:
                lookup_values[str(node_index)] = "No value connected"
                continue

            try:
                value = self.resolve_output(
                    connection.source_node_index,
                    connection.source_socket,
                    set(),
                )
                lookup_values[str(node_index)] = display_value(value)
            except ValueError as error:
                message = str(error)
                lookup_values[str(node_index)] = message
                self.errors.append(message)

        return lookup_values

    def resolve_output(self, node_index: int, socket: str, stack: set[int]) -> Any:
        cache_key = (node_index, socket)

        if cache_key in self.cache:
            return self.cache[cache_key]

        if node_index in stack:
            raise ValueError("Cycle detected while calculating graph.")

        if node_index < 0 or node_index >= len(self.nodes):
            raise ValueError(f"Node index {node_index} does not exist.")

        node = self.nodes[node_index]
        node_type = str(node.get("type", ""))
        next_stack = {*stack, node_index}
        value = self._evaluate_node(node_type, node, node_index, next_stack)

        self.cache[cache_key] = value
        return value

    def resolve_input(self, node_index: int, socket: str, stack: set[int]) -> Any:
        connection = self.input_sources.get((node_index, socket))

        if not connection:
            return 0

        return self.resolve_output(connection.source_node_index, connection.source_socket, stack)

    def _evaluate_node(
        self,
        node_type: str,
        node: dict[str, Any],
        node_index: int,
        stack: set[int],
    ) -> Any:
        if node_type in VALUE_NODE_TYPES:
            return coerce_node_value(node_type, node.get("value", 0))

        if node_type in GENERATOR_NODE_TYPES:
            return evaluate_generator(
                node_type,
                node.get("value", {}),
                lambda socket_name: self.resolve_input(node_index, socket_name, stack),
            )

        operation = MATH_NODE_TYPES.get(node_type)
        if operation:
            return apply_binary_operation(
                self.resolve_input(node_index, "a", stack),
                self.resolve_input(node_index, "b", stack),
                operation,
            )

        if node_type in CONDITION_NODE_TYPES:
            return evaluate_condition_node(
                node_type,
                node,
                lambda socket_name: self.resolve_input(node_index, socket_name, stack),
            )

        raise ValueError(f"{node_type or 'Unknown'} nodes do not produce values yet.")
