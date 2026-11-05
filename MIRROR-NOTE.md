# Review snapshot — read this first

This repository is a **squashed, point-in-time snapshot** of
`Cartilage-Stairwells/tscp-anchor` at commit
`c664991671f50ad5763c436ce73b30c1d0791a00` (2026-10-29), created 2026-11-02 and
made exact on 2026-11-04, so reviewers can clone in seconds. The canonical repo
carries roughly 301 MB of evidence history; this mirror carries the working tree
and no history.

- **Canonical repo (full history, sealed evidence):** `Cartilage-Stairwells/tscp-anchor`
- **Start here:** `README.md`, then `CLAIMS_STATEMENT.md`
- **If the two differ, the canonical repo governs.** Nothing here supersedes it.

## What is in here

**Every file in the canonical tree at that commit is present here, byte for byte:
396 of 396.** No file has been omitted, filtered, reformatted or summarised. The
only files that exist here and not in the canonical tree are the three pieces of
mirror apparatus:

| File | Purpose |
|---|---|
| `MIRROR-NOTE.md` | this note |
| `verify-mirror.sh` | checks this clone against the pin, and against the canonical repo |
| `MIRROR-MANIFEST.sha256` | digests of every other file here, so the clone is checkable offline |

Earlier builds of this snapshot dropped 13 build and log artifacts — eight `*.log`,
`.lake/config/0/lakefile.olean.trace`, `events.cbor`, and four
`migration-backups/plonky3-0.6.2-preflight/*.toml.bak` — 43 KB in total. Their
absence could not be told apart from damage by anyone inspecting this repository,
so they are now present and the copy is exact. This note records that change rather
than pretending it did not happen.

Those 13 paths match the canonical repo's own ignore rules even though they are
tracked there, so they had to be force-added here as well. As a result `git status`
in this clone reports them as ignored files that are tracked. That is expected, it
mirrors the canonical repo's state, and the manifest lists them because they exist.

## Check it yourself

No credentials are needed, because the canonical repo is public.

```bash
./verify-mirror.sh            # offline: does this clone match its own manifest?
./verify-mirror.sh --full     # also fetches tscp-anchor at the pin and compares content
```

`--full` fetches that exact commit into a temporary directory with
`git fetch --depth 1 <url> <sha>`, so it still works after the canonical branch
has moved on. Exit status 0 means the tree matches the pin; non-zero means it does
not, and the message says which files differ.

## This snapshot does not track the canonical repo

It is frozen at the pin above. When the canonical repo moves, this copy is behind
**by design**, and nothing here will notice unless someone runs the verifier. The
canonical repo is the only live surface.

To regenerate after the canonical repo moves, from a clone of this repository:

```bash
git clone --depth 1 https://github.com/Cartilage-Stairwells/tscp-anchor.git /tmp/anchor
rsync -a --delete --exclude .git /tmp/anchor/ ./          # exact copy of the new tree
git checkout -- MIRROR-NOTE.md verify-mirror.sh           # keep the apparatus
# update PIN in verify-mirror.sh and the commit in this note, then:
git ls-files -z | grep -zv '^MIRROR-MANIFEST.sha256$' | xargs -0 sha256sum > MIRROR-MANIFEST.sha256
./verify-mirror.sh --full
```

## What this is not

- Not evidence, and not a substitute for the sealed history in the canonical repo.
- Not reviewed or endorsed by the canonical repo's owner by virtue of existing.
- Not independently verified by whoever built the manifest: run `--full` yourself.
