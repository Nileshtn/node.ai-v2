from __future__ import annotations

from typing import Any


def as_list(value: Any) -> list[Any]:
    if isinstance(value, list):
        return value

    if hasattr(value, "toVariant"):
        variant_value = value.toVariant()
        if isinstance(variant_value, list):
            return variant_value

    return []


def coerce_node_value(node_type: str, value: Any) -> Any:
    if node_type == "Int":
        return int(float(value or 0))

    if node_type == "Float":
        return float(value or 0)

    if node_type in {"Vector 2D", "Vector 3D", "Vector 4D"}:
        expected_size = int(node_type.replace("Vector ", "").replace("D", ""))
        values = as_list(value)
        padded_values = [*values, *([0] * expected_size)]
        return [float(padded_values[index] or 0) for index in range(expected_size)]

    if node_type in {"Bool", "Button"}:
        return bool(value)

    if node_type == "Str":
        return str(value)

    return value


def apply_binary_operation(left: Any, right: Any, operation: str) -> Any:
    if isinstance(left, str) or isinstance(right, str):
        if operation == "add":
            return f"{left}{right}"

        raise ValueError("Text values only support Add.")

    if isinstance(left, list) or isinstance(right, list):
        return _apply_vector_operation(left, right, operation)

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


def _apply_vector_operation(left: Any, right: Any, operation: str) -> list[Any]:
    left_is_vector = isinstance(left, list)
    right_is_vector = isinstance(right, list)

    if left_is_vector and right_is_vector and len(left) != len(right):
        raise ValueError("Vector inputs must have the same size.")

    size = len(left) if left_is_vector else len(right)
    left_values = left if left_is_vector else [left] * size
    right_values = right if right_is_vector else [right] * size

    return [
        apply_binary_operation(left_values[index], right_values[index], operation)
        for index in range(size)
    ]


def display_value(value: Any) -> str:
    if isinstance(value, list):
        return "[" + ", ".join(display_value(item) for item in value) + "]"

    if isinstance(value, bool):
        return "true" if value else "false"

    return str(value)
