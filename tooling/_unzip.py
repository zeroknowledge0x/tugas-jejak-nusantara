import zipfile, os, glob

base = "/root/tugas-jejak-nusantara/tooling"
mapping = {
    "rojo.zip": "bin_rojo",
    "selene.zip": "bin_selene",
    "stylua.zip": "bin_stylua",
    "luau.zip": "bin_luau",
}
for zf, out in mapping.items():
    p = os.path.join(base, zf)
    if os.path.exists(p):
        os.makedirs(out, exist_ok=True)
        with zipfile.ZipFile(p) as z:
            z.extractall(out)
        print(f"extracted {zf} -> {out}")
    else:
        print("missing", p)

for d in glob.glob(os.path.join(base, "bin_*")):
    for root, _, files in os.walk(d):
        for f in files:
            print(os.path.join(root, f))
