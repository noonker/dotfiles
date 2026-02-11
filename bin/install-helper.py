import os
import argparse
import subprocess

WORD = "yoinked-"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')

    parser.add_argument('-d', '--dir', help=(''))

    args = parser.parse_args()

    prepare = [f for f in os.listdir(args.dir) if WORD in f and (f.endswith(".zip") or f.endswith(".iso")) ]

    for fname in prepare:
        dir_name = "".join(fname.split(WORD)[1:])[0:-4]
        print(f"preparing {dir_name}")
        new_dir = os.path.join(args.dir, dir_name)
        old_file = os.path.join(args.dir, fname)
        new_file = os.path.join(new_dir, fname)
        os.mkdir(new_dir)
        os.rename(old_file, new_file)
        subprocess.run(["7z", "x", new_file, f"-o{new_dir}", ])
        subprocess.run(["kgx", "-e", "distrobox enter bitwig"], cwd=new_dir)
