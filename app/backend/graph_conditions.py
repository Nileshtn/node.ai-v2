from __future__ import annotations

from typing import Any, Callable

COMPARE_OPS = frozenset({"eq", "neq", "lt", "lte", "gt", "gte"})


def as_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value

    if isinstance(value, (int, float)):
        return value != 0

    if isinstance(value, str):
        return len(value) > 0

    if isinstance(value, list):
        return len(value) > 0

    return bool(value)


def compare_values(left: Any, right: Any, op: str) -> bool:
    operation = str(op or "eq").lower()

    if operation not in COMPARE_OPS:
        raise ValueError(f"Unknown compare operator: {operation}")

    if operation == "eq":
        return left == right

    if operation == "neq":
        return left != right

    try:
        if operation == "lt":
            return left < right

        if operation == "lte":
            return left <= right

        if operation == "gt":
            return left > right

        if operation == "gte":
            return left >= right
    except TypeError as error:
        raise ValueError("Cannot compare these value types.") from error

    raise ValueError(f"Unknown compare operator: {operation}")


def evaluate_condition_node(
    node_type: str,
    node: dict[str, Any],
    resolve_input: Callable[[str], Any],
) -> Any:
    if node_type == "If Else":
        if as_bool(resolve_input("condition")):
            return resolve_input("then")

        return resolve_input("else")

    if node_type == "Switch":
        index_value = resolve_input("index")

        try:
            index = int(index_value)
        except (TypeError, ValueError):
            index = 0

        for case in ("0", "1", "2"):
            if index == int(case):
                return resolve_input(case)

        return resolve_input("default")

    if node_type == "Compare":
        node_value = node.get("value", {})
        operation = "eq"

        if isinstance(node_value, dict):
            operation = str(node_value.get("op", "eq"))

        return compare_values(resolve_input("a"), resolve_input("b"), operation)

    if node_type == "And":
        return as_bool(resolve_input("a")) and as_bool(resolve_input("b"))

    if node_type == "Or":
        return as_bool(resolve_input("a")) or as_bool(resolve_input("b"))

    if node_type == "Not":
        return not as_bool(resolve_input("a"))

    raise ValueError(f"{node_type or 'Unknown'} condition node is not supported.")
