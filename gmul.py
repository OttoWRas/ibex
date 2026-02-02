# --------------------------------------------
# GF(2^128) Reducer Mask Generator for GHASH
# Produces:
#   1. MASK[shift][bit]   (78-bit masks)
#   2. FOLD1[64]          single fold masks
#   3. FOLD2[7]           second fold masks
# --------------------------------------------

OFFSETS = [0,1,2,7]
SHIFTS  = [0,32,64,96,128,160,192]
MAXBIT  = 78    # Only keep bits 0..77 in output


def reduce_index(idx):
    """Return all final bit positions (<=MAXBIT-1) contributed by a single bit at index idx."""
    work = [idx]
    out  = []
    while work:
        t = work.pop()
        if t < 128:
            if t < MAXBIT:
                out.append(t)
        else:
            base = t - 128
            for o in OFFSETS:
                p = base + o
                if p < 128:
                    if p < MAXBIT:
                        out.append(p)
                else:
                    # second fold
                    base2 = p - 128
                    for o2 in OFFSETS:
                        p2 = base2 + o2
                        if p2 < MAXBIT:
                            out.append(p2)
    return sorted(set(out))


# ----------------------------------------------------
# 1. Build full MASK[7][64] tables
# ----------------------------------------------------
MASK = [[0]*64 for _ in range(7)]
for si, S in enumerate(SHIFTS):
    for b in range(64):
        idx = S + b
        pos = reduce_index(idx)
        mask = 0
        for p in pos:
            mask |= (1 << p)
        MASK[si][b] = mask


# ----------------------------------------------------
# 2. FOLD1: idx = 128..191 → k=0..63
# ----------------------------------------------------
FOLD1 = [0]*64
for k in range(64):
    idx = 128 + k
    pos = reduce_index(idx)
    mask = 0
    for p in pos:
        mask |= (1 << p)
    FOLD1[k] = mask


# ----------------------------------------------------
# 3. FOLD2: idx = 128..134 → k=0..6 (second fold only)
# ----------------------------------------------------
FOLD2 = [0]*7
for k in range(7):
    idx = 128 + k
    pos = reduce_index(idx)
    mask = 0
    for p in pos:
        mask |= (1 << p)
    FOLD2[k] = mask


# ----------------------------------------------------
# Helper: Format 78-bit hex safely on all Python versions
# ----------------------------------------------------
def hex78(x):
    # 20 hex chars = 80 bits → SV truncates to [77:0]
    return "78'h" + format(x, '020x')


# ----------------------------------------------------
# Emit the SystemVerilog tables
# ----------------------------------------------------

print("\n// =============================================")
print("// SystemVerilog MASK[7][64]  (78-bit outputs)")
print("// =============================================")
print("localparam logic [77:0] MASK [0:6][0:63] = '{")
for si in range(7):
    print(f"    '{{ // shift_idx = {si}")
    for b in range(64):
        print(f"        {hex78(MASK[si][b])},  // b={b}")
    print("    },")
print("};\n")

print("// =============================================")
print("// SystemVerilog FOLD1[64]  (first fold masks)")
print("// =============================================")
print("localparam logic [77:0] FOLD1 [0:63] = '{")
for k in range(64):
    print(f"    {hex78(FOLD1[k])}, // k={k}")
print("};\n")

print("// =============================================")
print("// SystemVerilog FOLD2[7]  (second fold masks)")
print("// =============================================")
print("localparam logic [77:0] FOLD2 [0:6] = '{")
for k in range(7):
    print(f"    {hex78(FOLD2[k])}, // k={k}")
print("};\n")
