"""Local steps of the regenerate-species-sprite skill. Run from the repository root.

    python .claude/skills/regenerate-species-sprite/sprite.py info <species|next>
    python .claude/skills/regenerate-species-sprite/sprite.py take <id>
    python .claude/skills/regenerate-species-sprite/sprite.py commit <id>
    python .claude/skills/regenerate-species-sprite/sprite.py discard <id>

info    finds the species by id, English or Latin name (or the next one on the README TODO list)
        and prints its id, names and the full ChatGPT prompt as a JSON string.
take    moves ~/Downloads/fishy_<id>.png to art_source/fish/views/<id>.png, cuts it with
        tools/extract_species_views.py and writes two images to look at: the source (preview.jpg)
        and the cut sprites on red (check.png) in build/sprite_check/.
commit  removes the species from the README TODO list, marks it "in the game" in the prompts
        table and commits the view image, the body and tail
        sprites (one commit per species). Of README and prompts.md only those two edits are
        committed; the user's other changes there stay unstaged.
discard restores the committed body and tail sprites and the committed view image (or deletes
        a new one) after a rejected drawing.
"""
import csv
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path.cwd()
SPECIES = ROOT / "data" / "species.csv"
README = ROOT / "README.md"
PROMPTS = ROOT / "art_source" / "fish" / "views" / "prompts.md"
VIEWS = ROOT / "art_source" / "fish" / "views"
SPRITES = ROOT / "assets" / "sprites" / "fish_painted"
CHECK = ROOT / "build" / "sprite_check"
DOWNLOADS = Path.home() / "Downloads"
TODO_HEAD = "- Regenerate the species sprites"
# A TODO entry may say why after the species: "  - Blue whale (Balaenoptera musculus) — reason".
REASON = " — "
CO_AUTHOR = "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"


def rows() -> list[dict]:
    return list(csv.DictReader(SPECIES.open(encoding="utf-8")))


def todo_lines() -> list[str]:
    """The species of the README's regeneration TODO, e.g. "Blue tang (Paracanthurus hepatus)" (the
    reason after " — " left off)."""
    lines = README.read_text(encoding="utf-8").splitlines()
    start = next(i for i, line in enumerate(lines) if line.startswith(TODO_HEAD))
    out = []
    for line in lines[start + 1:]:
        if not line.startswith("  - "):
            break
        out.append(line[4:].split(REASON)[0].strip())
    return out


def label(row: dict) -> str:
    return f"{row['common_name']} ({row['scientific_name']})"


def find(query: str) -> dict:
    if query == "next":
        todo = todo_lines()
        if not todo:
            sys.exit("The README TODO list is empty: all species are done.")
        query = todo[0]
    q = query.strip().lower()
    for row in rows():
        if q in (row["id"], row["common_name"].lower(), row["scientific_name"].lower(), label(row).lower()):
            return row
    hits = [row for row in rows() if q in label(row).lower() or q in row["id"]]
    if len(hits) == 1:
        return hits[0]
    names = ", ".join(label(r) for r in hits) or "none"
    sys.exit(f"No single species matches {query!r} (matches: {names}).")


def prompt(species_id: str) -> str:
    text = PROMPTS.read_text(encoding="utf-8")
    section = re.search(r"^## .*`%s`\n(.*?)(?=^## |\Z)" % re.escape(species_id), text, re.M | re.S)
    if not section:
        sys.exit(f"No prompt for {species_id} in {PROMPTS} (add it in tools/make_species_view_prompts.py).")
    body = re.search(r"```\n(.*?)```", section.group(1), re.S).group(1)
    return "\n\n".join(" ".join(p.split()) for p in body.strip().split("\n\n"))


def info(query: str) -> None:
    row = find(query)
    print(json.dumps({
        "id": row["id"],
        "name": label(row),
        "on_todo_list": label(row) in todo_lines(),
        "has_view_image": (VIEWS / f"{row['id']}.png").exists(),
        "download_name": f"fishy_{row['id']}.png",
        "prompt": prompt(row["id"]),
    }, ensure_ascii=False, indent=1))


def take(species_id: str) -> None:
    from PIL import Image

    src = DOWNLOADS / f"fishy_{species_id}.png"
    for _ in range(10):
        if src.exists():
            break
        time.sleep(1)
    else:
        sys.exit(f"{src} not found. Chrome may block automatic downloads from chatgpt.com: ask the user to allow them.")
    dest = VIEWS / f"{species_id}.png"
    shutil.move(src, dest)
    subprocess.run([sys.executable, "tools/extract_species_views.py", species_id], check=True)
    CHECK.mkdir(parents=True, exist_ok=True)
    Image.open(dest).convert("RGB").resize((768, 512)).save(CHECK / "preview.jpg")
    parts = [Image.open(SPRITES / f"{species_id}_{n}.png").convert("RGBA") for n in ("body", "tail")]
    sheet = Image.new("RGBA", (sum(p.width for p in parts) + 30, max(p.height for p in parts)), (200, 40, 40, 255))
    x = 0
    for part in parts:
        sheet.alpha_composite(part, (x, 0))
        x += part.width + 10
    sheet.save(CHECK / "check.png")
    print(f"Look at {CHECK / 'preview.jpg'} and {CHECK / 'check.png'}")


def stage_edit(path: Path, edit) -> None:
    """Applies `edit` (text -> text) to the file and, separately, to its staged version, and stages
    only that: the user's other uncommitted changes in the file stay unstaged."""
    path.write_text(edit(path.read_text(encoding="utf-8")), encoding="utf-8", newline="")
    rel = path.relative_to(ROOT).as_posix()
    staged = subprocess.run(["git", "show", f":{rel}"], capture_output=True, check=True).stdout.decode("utf-8")
    blob = subprocess.run(["git", "hash-object", "-w", "--stdin"], input=edit(staged).encode("utf-8"),
                          capture_output=True, check=True).stdout.decode().strip()
    mode = subprocess.run(["git", "ls-files", "-s", "--", rel], capture_output=True, check=True).stdout.decode().split()[0]
    subprocess.run(["git", "update-index", "--cacheinfo", f"{mode},{blob},{rel}"], check=True)


def commit(species_id: str) -> None:
    row = find(species_id)

    def drop_entry(text: str) -> str:
        return re.sub(r"^  - %s(%s[^\r\n]*)? *\r?\n" % (re.escape(label(row)), re.escape(REASON)), "", text, count=1, flags=re.M)

    def mark_in_game(text: str) -> str:
        return re.sub(r"^(\| `%s` \| [^|\n]*?) \|(?=\r?$)" % re.escape(species_id),
                      lambda m: m.group(0) if "in the game" in m.group(1) else m.group(1) + " – in the game (side view) |",
                      text, count=1, flags=re.M)

    if label(row) not in todo_lines():
        print("Note: the species was not on the README TODO list.")
    stage_edit(README, drop_entry)
    stage_edit(PROMPTS, mark_in_game)
    files = [VIEWS / f"{species_id}.png"]
    for part in ("body", "tail"):
        for suffix in (".png", ".png.import"):
            path = SPRITES / f"{species_id}_{part}{suffix}"
            if path.exists():
                files.append(path)
    subprocess.run(["git", "add", "--", *map(str, files)], check=True)
    message = f"New cute-comic sprite for the {row['common_name']} (one image per species)"
    subprocess.run(["git", "commit", "-q", "-m", message, "-m", CO_AUTHOR], check=True)
    subprocess.run(["git", "log", "--oneline", "-1"], check=True)
    print(f"{len(todo_lines())} species left on the TODO list.")


def discard(species_id: str) -> None:
    sprites = [f"assets/sprites/fish_painted/{species_id}_{p}.png" for p in ("body", "tail")]
    subprocess.run(["git", "checkout", "--", *sprites], check=False)
    # A species drawn again (e.g. for thinner outlines) gets its committed view image back.
    view = VIEWS / f"{species_id}.png"
    if subprocess.run(["git", "ls-files", "--error-unmatch", str(view)], capture_output=True).returncode == 0:
        subprocess.run(["git", "checkout", "HEAD", "--", str(view)], check=True)
    else:
        view.unlink(missing_ok=True)
    print(f"Discarded the new drawing of {species_id}.")


def main() -> None:
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    command, arg = sys.argv[1], " ".join(sys.argv[2:])
    {"info": info, "take": take, "commit": commit, "discard": discard}[command](arg)


main()
