from __future__ import annotations

import random
from typing import Any, Callable


def evaluate_generator(
    node_type: str,
    value: Any,
    resolve_input: Callable[[str], Any],
) -> Any:
    params = value if isinstance(value, dict) else {}

    if node_type == "Random":
        return shape_value(params, lambda: random.uniform(0, 1))

    if node_type == "Random Int":
        minimum = int(number_param(params, "min", 0))
        maximum = int(number_param(params, "max", 10))
        low = min(minimum, maximum)
        high = max(minimum, maximum)
        return shape_value(params, lambda: random.randint(low, high))

    if node_type == "Ones":
        return shape_value(params, lambda: 1)

    if node_type == "Zeros":
        return shape_value(params, lambda: 0)

    if node_type == "Range":
        return range_values(
            number_param(params, "start", 0),
            number_param(params, "stop", 10),
            number_param(params, "step", 1),
        )

    if node_type == "Random Like":
        return like_value(resolve_input("like"), lambda: random.uniform(0, 1))

    if node_type == "Ones Like":
        return like_value(resolve_input("like"), lambda: 1)

    if node_type == "Zeros Like":
        return like_value(resolve_input("like"), lambda: 0)

    raise ValueError(f"{node_type} is not supported.")


def number_param(params: dict[str, Any], key: str, default: float) -> float:
    try:
        return float(params.get(key, default))
    except (TypeError, ValueError):
        return default


def shape_value(params: dict[str, Any], make_value: Callable[[], Any]) -> Any:
    shape = shape_param(params)

    if not shape:
        return make_value()

    return build_shape(shape, make_value)


def shape_param(params: dict[str, Any]) -> list[int]:
    raw_shape = params.get("shape", params.get("count", "1"))

    if isinstance(raw_shape, (int, float)):
        return [max(1, int(raw_shape))]

    if isinstance(raw_shape, list):
        return [max(1, int(float(part))) for part in raw_shape if shape_part_valid(part)]

    shape_text = str(raw_shape).strip()

    if not shape_text:
        return [1]

    for character in "[]()":
        shape_text = shape_text.replace(character, "")

    shape_text = shape_text.replace("x", ",").replace("X", ",")
    parts = [part.strip() for part in shape_text.split(",") if part.strip()]
    shape = [max(1, int(float(part))) for part in parts if shape_part_valid(part)]

    return shape or [1]


def shape_part_valid(value: Any) -> bool:
    try:
        float(value)
    except (TypeError, ValueError):
        return False

    return True


def build_shape(shape: list[int], make_value: Callable[[], Any]) -> Any:
    total_size = 1

    for dimension in shape:
        total_size *= dimension

        if total_size > 1000:
            raise ValueError("Shape is too large. Use 1000 values or fewer.")

    if len(shape) == 1:
        return [make_value() for _ in range(shape[0])]

    return [build_shape(shape[1:], make_value) for _ in range(shape[0])]


def range_values(start: float, stop: float, step: float) -> list[float]:
    if step == 0:
        raise ValueError("Range step cannot be 0.")

    values: list[float] = []
    current = start
    limit = 1000

    while len(values) < limit and ((step > 0 and current < stop) or (step < 0 and current > stop)):
        values.append(current)
        current += step

    return values


def like_value(source: Any, make_value: Callable[[], Any]) -> Any:
    if isinstance(source, list):
        return [like_value(item, make_value) for item in source]

    return make_value()
