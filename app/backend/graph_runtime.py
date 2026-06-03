from __future__ import annotations

from dataclasses import dataclass
import random
from typing import Any

from PySide6.QtCore import QObject, Slot


@dataclass(frozen=True)
class GraphConnection:
    source_node_index: int
    source_socket: str
    target_node_index: int
    target_socket: str


class GraphRuntime(QObject):
    """Calculation backend for the visual node graph."""

    VALUE_NODE_TYPES = {
        "Int",
        "Float",
        "Vector 2D",
        "Vector 3D",
        "Vector 4D",
        "Bool",
        "Str",
        "Button",
    }

    GENERATOR_NODE_TYPES = {
        "Random",
        "Random Like",
        "Ones",
        "Ones Like",
        "Zeros",
        "Zeros Like",
        "Random Int",
        "Range",
    }

    @Slot("QVariant", "QVariant", result="QVariant")
    def evaluate(self, nodes: Any, connections: Any) -> dict[str, Any]:
        graph_nodes = self._as_list(nodes)
        graph_connections = [
            GraphConnection(
                source_node_index=int(connection.get("sourceNodeIndex", -1)),
                source_socket=str(connection.get("sourceSocket", "")),
                target_node_index=int(connection.get("targetNodeIndex", -1)),
                target_socket=str(connection.get("targetSocket", "")),
            )
            for connection in self._as_list(connections)
            if isinstance(connection, dict)
        ]

        input_sources = {
            (connection.target_node_index, connection.target_socket): connection
            for connection in graph_connections
        }
        cache: dict[tuple[int, str], Any] = {}
        errors: list[str] = []

        def resolve_output(node_index: int, socket: str, stack: set[int]) -> Any:
            cache_key = (node_index, socket)

            if cache_key in cache:
                return cache[cache_key]

            if node_index in stack:
                raise ValueError("Cycle detected while calculating graph.")

            if node_index < 0 or node_index >= len(graph_nodes):
                raise ValueError(f"Node index {node_index} does not exist.")

            node = graph_nodes[node_index]
            node_type = str(node.get("type", ""))
            next_stack = {*stack, node_index}

            if node_type in self.VALUE_NODE_TYPES:
                value = self._node_value(node_type, node.get("value", 0))
            elif node_type in self.GENERATOR_NODE_TYPES:
                value = self._generator_value(
                    node_type,
                    node.get("value", {}),
                    lambda socket_name: resolve_input(node_index, socket_name, next_stack),
                )
            elif node_type == "Add":
                value = self._apply_binary_operation(
                    resolve_input(node_index, "a", next_stack),
                    resolve_input(node_index, "b", next_stack),
                    "add",
                )
            elif node_type == "Sub":
                value = self._apply_binary_operation(
                    resolve_input(node_index, "a", next_stack),
                    resolve_input(node_index, "b", next_stack),
                    "sub",
                )
            elif node_type == "Mul":
                value = self._apply_binary_operation(
                    resolve_input(node_index, "a", next_stack),
                    resolve_input(node_index, "b", next_stack),
                    "mul",
                )
            elif node_type == "Div":
                value = self._apply_binary_operation(
                    resolve_input(node_index, "a", next_stack),
                    resolve_input(node_index, "b", next_stack),
                    "div",
                )
            else:
                raise ValueError(f"{node_type or 'Unknown'} nodes do not produce values yet.")

            cache[cache_key] = value
            return value

        def resolve_input(node_index: int, socket: str, stack: set[int]) -> Any:
            connection = input_sources.get((node_index, socket))

            if not connection:
                return 0

            return resolve_output(connection.source_node_index, connection.source_socket, stack)

        lookup_values: dict[str, str] = {}

        for node_index, node in enumerate(graph_nodes):
            if str(node.get("type", "")) != "Lookup":
                continue

            connection = input_sources.get((node_index, "value"))

            if not connection:
                lookup_values[str(node_index)] = "No value connected"
                continue

            try:
                value = resolve_output(connection.source_node_index, connection.source_socket, set())
                display_value = self._display_value(value)
                lookup_values[str(node_index)] = display_value
                print(f"Lookup[{node_index}] = {display_value}", flush=True)
            except ValueError as error:
                message = str(error)
                lookup_values[str(node_index)] = message
                errors.append(message)

        if errors:
            return {
                "ok": False,
                "message": errors[0],
                "lookupValues": lookup_values,
            }

        return {
            "ok": True,
            "message": "Graph computed",
            "lookupValues": lookup_values,
        }

    def _node_value(self, node_type: str, value: Any) -> Any:
        if node_type == "Int":
            return int(float(value or 0))

        if node_type == "Float":
            return float(value or 0)

        if node_type in {"Vector 2D", "Vector 3D", "Vector 4D"}:
            expected_size = int(node_type.replace("Vector ", "").replace("D", ""))
            values = self._as_list(value)
            padded_values = [*values, *([0] * expected_size)]
            return [float(padded_values[index] or 0) for index in range(expected_size)]

        if node_type in {"Bool", "Button"}:
            return bool(value)

        if node_type == "Str":
            return str(value)

        return value

    def _generator_value(self, node_type: str, value: Any, input_value: Any) -> Any:
        params = value if isinstance(value, dict) else {}

        if node_type == "Random":
            return self._shape_value(params, lambda: random.uniform(0, 1))

        if node_type == "Random Int":
            minimum = int(self._number_param(params, "min", 0))
            maximum = int(self._number_param(params, "max", 10))
            low = min(minimum, maximum)
            high = max(minimum, maximum)
            return self._shape_value(params, lambda: random.randint(low, high))

        if node_type == "Ones":
            return self._shape_value(params, lambda: 1)

        if node_type == "Zeros":
            return self._shape_value(params, lambda: 0)

        if node_type == "Range":
            return self._range_values(
                self._number_param(params, "start", 0),
                self._number_param(params, "stop", 10),
                self._number_param(params, "step", 1),
            )

        if node_type == "Random Like":
            return self._like_value(input_value("like"), lambda: random.uniform(0, 1))

        if node_type == "Ones Like":
            return self._like_value(input_value("like"), lambda: 1)

        if node_type == "Zeros Like":
            return self._like_value(input_value("like"), lambda: 0)

        raise ValueError(f"{node_type} is not supported.")

    def _number_param(self, params: dict[str, Any], key: str, default: float) -> float:
        try:
            return float(params.get(key, default))
        except (TypeError, ValueError):
            return default

    def _count_param(self, params: dict[str, Any]) -> int:
        return max(1, int(self._number_param(params, "count", 1)))

    def _shape_value(self, params: dict[str, Any], make_value: Any) -> Any:
        shape = self._shape_param(params)

        if not shape:
            return make_value()

        return self._build_shape(shape, make_value)

    def _shape_param(self, params: dict[str, Any]) -> list[int]:
        raw_shape = params.get("shape", params.get("count", "1"))

        if isinstance(raw_shape, (int, float)):
            return [max(1, int(raw_shape))]

        if isinstance(raw_shape, list):
            return [max(1, int(float(part))) for part in raw_shape if self._shape_part_valid(part)]

        shape_text = str(raw_shape).strip()

        if not shape_text:
            return [1]

        for character in "[]()":
            shape_text = shape_text.replace(character, "")

        shape_text = shape_text.replace("x", ",").replace("X", ",")
        parts = [part.strip() for part in shape_text.split(",") if part.strip()]
        shape = [max(1, int(float(part))) for part in parts if self._shape_part_valid(part)]

        return shape or [1]

    def _shape_part_valid(self, value: Any) -> bool:
        try:
            float(value)
        except (TypeError, ValueError):
            return False

        return True

    def _build_shape(self, shape: list[int], make_value: Any) -> Any:
        total_size = 1

        for dimension in shape:
            total_size *= dimension

            if total_size > 1000:
                raise ValueError("Shape is too large. Use 1000 values or fewer.")

        if len(shape) == 1:
            return [make_value() for _ in range(shape[0])]

        return [self._build_shape(shape[1:], make_value) for _ in range(shape[0])]

    def _range_values(self, start: float, stop: float, step: float) -> list[float]:
        if step == 0:
            raise ValueError("Range step cannot be 0.")

        values: list[float] = []
        current = start
        limit = 1000

        while len(values) < limit and ((step > 0 and current < stop) or (step < 0 and current > stop)):
            values.append(current)
            current += step

        return values

    def _like_value(self, source: Any, make_value: Any) -> Any:
        if isinstance(source, list):
            return [self._like_value(item, make_value) for item in source]

        return make_value()

    def _apply_binary_operation(self, left: Any, right: Any, operation: str) -> Any:
        if isinstance(left, str) or isinstance(right, str):
            if operation == "add":
                return f"{left}{right}"

            raise ValueError("Text values only support Add.")

        if isinstance(left, list) or isinstance(right, list):
            return self._apply_vector_operation(left, right, operation)

        if operation == "add":
            return left + right

        if operation == "sub":
            return left - right

        if operation == "mul":
            return left * right

        if operation == "div":
            if right == 0:
                raise ValueError("Cannot divide by zero.")

            return left / right

        raise ValueError(f"Unsupported operation: {operation}")

    def _apply_vector_operation(self, left: Any, right: Any, operation: str) -> list[Any]:
        left_is_vector = isinstance(left, list)
        right_is_vector = isinstance(right, list)

        if left_is_vector and right_is_vector and len(left) != len(right):
            raise ValueError("Vector inputs must have the same size.")

        size = len(left) if left_is_vector else len(right)
        left_values = left if left_is_vector else [left] * size
        right_values = right if right_is_vector else [right] * size

        return [
            self._apply_binary_operation(left_values[index], right_values[index], operation)
            for index in range(size)
        ]

    def _display_value(self, value: Any) -> str:
        if isinstance(value, list):
            return "[" + ", ".join(self._display_value(item) for item in value) + "]"

        if isinstance(value, bool):
            return "true" if value else "false"

        return str(value)

    def _as_list(self, value: Any) -> list[Any]:
        if isinstance(value, list):
            return value

        if hasattr(value, "toVariant"):
            variant_value = value.toVariant()
            if isinstance(variant_value, list):
                return variant_value

        return []
