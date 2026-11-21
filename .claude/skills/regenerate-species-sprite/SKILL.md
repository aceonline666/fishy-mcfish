---
name: regenerate-species-sprite
description: Regenerate a species' sprites in the cute-comic style with ChatGPT's image generator in Chrome, cut them, check them and commit one species per commit (removing it from the README TODO list). Use when the user runs /regenerate-species-sprite <species> (id, English or Latin name, several names, or "next" / "all"), or asks to regenerate / redraw a species sprite.
argument-hint: <species id | English name | Latin name | next | all> [...]
---

# Regenerate species sprites

Arguments: one or more species (id, English or Latin name), `next` (the first species on the
README TODO list "Regenerate the species sprites ...") or `all` (work down that list until it is
empty or ChatGPT's image limit is reached). No argument means `next`.

Helper (run from the repo root): `python .claude/skills/regenerate-species-sprite/sprite.py`
with `info`, `take`, `commit`, `discard` (see its docstring).

## Per species

1. **Look it up**: `sprite.py info <species>`. It prints the id, the name and the full prompt.
   Ambiguous names list the matches: pick the right one or ask.
2. **Open a fresh chat**: load the Chrome tools (tabs_context_mcp, tabs_create_mcp, navigate,
   computer, find, file_upload, javascript_tool, get_page_text, browser_batch), then
   `navigate` to `https://chatgpt.com/` (a full reload, so no hidden old composers remain).
   The user must be logged in; never type credentials.
3. **Inject the helpers** (after every reload) with `javascript_tool`:
   ```js
   window.__ed=()=>[...document.querySelectorAll('.ProseMirror[contenteditable=true]')].filter(e=>e.offsetParent).pop();
   window.__paste=(t)=>{const el=window.__ed(); el.focus(); const dt=new DataTransfer(); dt.setData('text/plain',t); el.dispatchEvent(new ClipboardEvent('paste',{clipboardData:dt,bubbles:true,cancelable:true})); return [t.length, el.innerText.length]};
   window.__send=()=>{const b=[...document.querySelectorAll('button[aria-label=Senden], button[aria-label=Send], #composer-submit-button')].filter(e=>e.offsetParent).pop(); if(!b) return 'no send button'; b.click(); return 'sent'};
   window.__st=()=>[location.pathname, !!document.querySelector('[data-testid=stop-button]'), [...document.querySelectorAll('main img')].filter(i=>i.offsetParent).map(i=>i.alt)];
   window.__dl=async(name)=>{const img=[...document.querySelectorAll('main img')].filter(i=>/^(Generiertes|Generated)/.test(i.alt)&&i.offsetParent).pop(); if(!img) return 'no image'; const b=await (await fetch(img.src)).blob(); const a=document.createElement('a'); a.href=URL.createObjectURL(b); a.download=name; document.body.appendChild(a); a.click(); a.remove(); return [b.type,b.size]};
   'ok'
   ```
4. **Prompt**: focus the box (`window.__ed().focus()`), press `ctrl+a` and `Delete` with the
   computer tool (ChatGPT sometimes restores a draft), then `window.__paste(<prompt as JSON string>)`.
   The two numbers it returns must be equal, or clear and paste again.
5. **Reference image**: `find` "Dateien anhängen / attach files file input", take the one with the
   highest ref number, and `file_upload` the absolute path of
   `art_source/fish/species_style_side.png` (the cod from the side) to it (never click it). Zoom on
   the composer to see the cod thumbnail. Without it the style drifts (thin outlines, realistic):
   do not send.
6. **Send** with `window.__send()` (a click on the arrow misses when the window size changed),
   then wait in a batch of 10 s waits (about 60 s) and check `window.__st()`: done when the stop
   button is gone and the list shows `Benutzeranhang` (the reference) and a generated image.
   Still running: wait again. No image: read the page text (get_page_text). On
   "Limit für Bilder erreicht" / "image limit": stop the whole run and report the reset time.
7. **Download**: `await window.__dl('fishy_<id>.png')`, then `sprite.py take <id>`. If the file
   does not arrive, Chrome blocks automatic downloads from chatgpt.com: ask the user to allow
   them (the icon in the address bar), do not change browser settings yourself.
8. **Check** `build/sprite_check/preview.jpg` and `check.png` (Read both):
   - one side view, head left (a squid or octopus mantle first, arms and tentacles only at the
     trailing end; rays in a three-quarter view from a little above); jellyfish (and the man o'
     war) have no direction: upright, the bell centred over tentacles hanging straight down
     (the game pulses the bell and sways the tentacles);
   - the style matches the cod (dark outlines, cel shading, big eyes), with the outline thickness
     the prompt's "Outlines:" line asks for: the bigger the game shows the species, the thinner
     (a whale about an eighth of the cod's), small fish bolder;
   - the side view suits the animation: a tail fin behind a narrow tail root, a straight body for
     wave swimmers, flat wings for rays, free flippers and legs;
   - the anatomy is right for the species (band count, eye count, body shape, fins) and it has
     not drifted towards the cod: the characteristic features are
     clearly there (the basking shark's long snout, a wrasse's hump); compare with the old
     sprite in `assets/sprites/fish_painted/<id>_body.png` (`git show HEAD:...`), it must not
     look worse;
   - the cut sprites on red: nothing missing (belly, fins), no background left (checkerboard
     between fins), the tail split looks right.
   A clear error: `sprite.py discard <id>`, then ask in the same chat for a redraw naming the
   errors precisely (paste the text, `__send()`, wait, `__dl`, `take` again). One redraw per
   species; if it is still wrong, discard it, keep the species on the list and tell the user.
   Small flaws (an extra small fin): accept and mention them in the report.
9. **Commit**: `sprite.py commit <id>`. It removes the species from the README TODO list, marks it
   in the prompts table and commits only that species' files (the user's other changes stay
   unstaged). Do not push unless asked.

## Notes

- The ChatGPT account is on the Free plan: about 10 images per 24 h, redraws included.
- Cutter problems (a silvery fish losing its belly, checkerboard left between arms) are fixed
  in `tools/extract_species_views.py`; re-cut all view images afterwards and compare with the
  committed sprites before committing the tool change on its own.
- Sprites are cut at the default scale 0.5 like the other new-style species; mipmaps are already
  on in the existing body and tail `.import` files. A species without a sprite yet needs mipmaps
  turned on in its new `.import` files (see the README).
- Close the tab you opened when the run ends, and report per species: done, discarded, or left.
