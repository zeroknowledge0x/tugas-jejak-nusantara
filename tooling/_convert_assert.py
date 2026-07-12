import re, glob, os

base = "/root/tugas-jejak-nusantara/src"
files = glob.glob(base + "/**/*.luau", recursive=True)

# Only convert in system modules that use module-level `save!`
pattern_save_bang = re.compile(r'\bsave!\.')

def convert(text):
    if 'save!.' not in text:
        return text, False
    # Replace save!. with save.
    text = text.replace('save!.', 'save.')
    # Add assert(save, "...") at start of each function that uses save
    # Find function blocks and ensure assert present.
    lines = text.split('\n')
    out = []
    i = 0
    n = len(lines)
    changed = True
    while i < n:
        line = lines[i]
        out.append(line)
        # detect a function declaration line (local function X or function X or X = function)
        is_func = bool(re.match(r'^\s*(local\s+)?function\b', line) or re.match(r'^\s*\S+\s*=\s*function\b', line))
        if is_func and i + 1 < n:
            # gather this function's body until matching end (simple indentation-based won't work; use balance)
            # Instead: look ahead; if body references save and lacks an assert already, insert assert right after decl
            depth = 0
            j = i
            body = []
            # compute function end by counting 'function'/'end' (rough but ok for luau)
            buf = line
            # Count to find matching end
            fc = buf.count('function') + buf.count('if')*0
            # Simpler: scan forward counting 'function' vs 'end' tokens
            count = 0
            k = i
            started = False
            while k < n:
                l = lines[k]
                count += l.count('function') + l.count('if ') + l.count('then')*0
                # count 'end'
                count -= l.count('end')
                if k == i:
                    count = 1  # one function opened
                body.append(l)
                if count <= 0 and k > i:
                    break
                k += 1
            func_text = '\n'.join(body)
            if 'save.' in func_text and 'assert(save' not in func_text:
                # insert assert after the declaration line (out already has decl)
                indent = re.match(r'^(\s*)', lines[i+1]).group(1) if i+1 < n else '\t'
                out.append(indent + 'assert(save, "system not initialized")')
        i += 1
    return '\n'.join(out), True

count_changed = 0
for f in files:
    with open(f) as fh:
        t = fh.read()
    nt, did = convert(t)
    if did:
        with open(f, 'w') as fh:
            fh.write(nt)
        count_changed += 1
        print("converted", f)
print("total converted:", count_changed)
