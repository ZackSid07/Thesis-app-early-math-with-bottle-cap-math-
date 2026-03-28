levels_raw = """
Category: Single-Digit Addition
1: 1 + 2 = 3
2: 1 + 4 = 5
3: 1 + 6 = 7
4: 2 + 6 = 8
5: 2 + 7 = 9
6: 3 + 5 = 8
7: 4 + 5 = 9

Category: Single-Digit Subtraction
8: 9 - 1 = 8
9: 9 - 2 = 7
10: 9 - 4 = 5
11: 8 - 3 = 5
12: 7 - 1 = 6
13: 7 - 5 = 2
14: 6 - 2 = 4

Category: Double-Digit + Single-Digit
15: 24 + 7 = 31
16: 25 + 9 = 34
17: 38 + 7 = 45
18: 74 + 6 = 80

Category: Double-Digit - Single-Digit
19: 34 - 5 = 29
20: 50 - 8 = 42
21: 80 - 6 = 74
22: 92 - 5 = 87

Category: Double-Digit + Double-Digit
23: 14 + 25 = 39
24: 27 + 38 = 65
25: 34 + 56 = 90
"""

category = ""
for line in levels_raw.strip().split('\n'):
    line = line.strip()
    if not line: continue
    if line.startswith("Category:"):
        category = line.split("Category: ")[1]
    else:
        lvl_num, eq = line.split(": ")
        parts = eq.split(" ")
        # parts is e.g. ["1", "+", "2", "=", "3"]
        arr = f'["{parts[0]}", "{parts[1]}", "{parts[2]}", "{parts[3]}", "?"]'
        state = "LevelState.current" if lvl_num == "1" else "LevelState.locked"
        print(f'''    LevelData(
        levelNumber: {lvl_num},
        category: "{category}",
        equation: {arr},
        expectedEquation: "{eq}",
        state: {state}),''')
