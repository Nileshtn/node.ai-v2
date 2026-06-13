from __future__ import annotations

VALUE_NODE_TYPES = frozenset({
    "Int",
    "Float",
    "Vector 2D",
    "Vector 3D",
    "Vector 4D",
    "Bool",
    "Str",
    "Button",
})

GENERATOR_NODE_TYPES = frozenset({
    "Random",
    "Random Like",
    "Ones",
    "Ones Like",
    "Zeros",
    "Zeros Like",
    "Random Int",
    "Range",
})

MATH_NODE_TYPES = {
    "Add": "add",
    "Sub": "sub",
    "Mul": "mul",
    "Div": "div",
}

CONDITION_NODE_TYPES = frozenset({
    "If Else",
    "Switch",
    "Compare",
    "And",
    "Or",
    "Not",
})
