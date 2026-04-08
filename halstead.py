import os
import math
import re

# Dart operators list
operators = [
    r'\+', '-', r'\*', '/', '%',
    '==', '!=', '<=', '>=', '<', '>',
    '=', r'\+=', '-=', r'\*=', '/=',
    '&&', r'\|\|', '!',
    'if', 'else', 'for', 'while', 'switch', 'case',
    'return', 'break', 'continue',
    'class', 'void', 'int', 'double', 'String', 'bool',
    'new', 'const', 'final', 'var'
]

operator_pattern = re.compile('|'.join(operators))


def analyze_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        code = f.read()

    tokens = re.findall(r'\w+|[^\s\w]', code)

    op_count = 0
    operand_count = 0
    unique_ops = set()
    unique_operands = set()

    for token in tokens:
        if operator_pattern.fullmatch(token):
            op_count += 1
            unique_ops.add(token)
        elif re.match(r'\w+', token):
            operand_count += 1
            unique_operands.add(token)

    return len(unique_ops), len(unique_operands), op_count, operand_count


def analyze_project(root):
    n1 = n2 = N1 = N2 = 0

    for subdir, _, files in os.walk(root):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(subdir, file)
                u1, u2, t1, t2 = analyze_file(filepath)

                n1 += u1
                n2 += u2
                N1 += t1
                N2 += t2

    return n1, n2, N1, N2


def halstead(n1, n2, N1, N2):
    n = n1 + n2
    N = N1 + N2

    V = N * math.log2(n) if n > 0 else 0
    D = (n1 / 2) * (N2 / n2) if n2 > 0 else 0
    E = D * V
    T = E / 18
    B = (E ** (2 / 3)) / 3000 if E > 0 else 0

    return n, N, V, D, E, T, B


if __name__ == "__main__":
    project_path = "."

    n1, n2, N1, N2 = analyze_project(project_path)

    n, N, V, D, E, T, B = halstead(n1, n2, N1, N2)

    print("\nHalstead Metrics for Project\n")
    print(f"Distinct Operators (n1): {n1}")
    print(f"Distinct Operands  (n2): {n2}")
    print(f"Total Operators    (N1): {N1}")
    print(f"Total Operands     (N2): {N2}")
    print(f"\nVocabulary (n): {n}")
    print(f"Program Length (N): {N}")
    print(f"Volume (V): {V:.2f}")
    print(f"Difficulty (D): {D:.2f}")
    print(f"Effort (E): {E:.2f}")
    print(f"Time (T): {T:.2f} seconds")
    print(f"Estimated Bugs (B): {B:.4f}")