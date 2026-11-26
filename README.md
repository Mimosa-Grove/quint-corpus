# quint-corpus

Part of the Mimosa Grove toolchain for Quint.

This repository is the single source of truth for a corpus of real Quint
specifications. Two tools read these bytes and must agree about them:

- **[quint-checktrace](https://github.com/Mimosa-Grove/quint-checktrace)**
  runs its fixture tests over these entries.
- **[quint-audit](https://github.com/Mimosa-Grove/quint-audit)** sweeps the
  entries as its drift detector. Its findings over this fixed population move
  when the audit changes.

quint-audit checks its verified specification set against this corpus.
This corpus is also the reference population for any later version of the audit
that reads the [Quint](https://quint.sh) 0.34.0 declaration kinds.

## Layout

| group | contents | entries |
|---|---|---|
| `corpus/real/` | specifications written for the Maintainer's personal projects, taken from their respective repositories | 47 |
| `corpus/third-party/` | upstream specifications, vendored with their licence texts | 18 |
| `corpus/synthetic/` | synthetic entries written for the corpus, two at 0.33.1 and eight at 0.34.0 | 10 |

`corpus/PROVENANCE.md` is the authority for every entry: origin, licence,
declared minimum Quint version and a SHA-256 digest of the file's bytes. A file
whose digest does not match that table has changed. A file with no row never
received provenance.

## Quint versions

Every entry declares a minimum Quint version in its provenance row. The eight
entries written for 0.34.0 also state it in their first comment lines.

- The 67 entries with `min_quint` 0.33.1 parse and typecheck under 0.33.1 and
  parse under 0.34.0.
- The eight entries with `min_quint` 0.34.0 parse under 0.34.0, and 0.33.1
  refuses them. Seven of them also pass the 0.34.0 typechecker. The
  `parameterised-properties` entry is parse-only: the 0.34.0 typechecker
  refuses parameters on the `invariant` and `observation` kinds, and the parser
  accepts them.

## Using the corpus

Clone the repository and point a tool at the directory it needs:

```sh
git clone https://github.com/Mimosa-Grove/quint-corpus.git
```

A sweep with quint-audit over every entry, one report per entry, from the
repository root:

```sh
out=$(mktemp -d)
for spec in $(git ls-files 'corpus/*.qnt'); do
  mkdir -p "$out/$(dirname "$spec")"
  quint-audit lint --format=json --quint /path/to/quint "$spec" > "$out/$spec.json"
done
```

The reports land in a fresh temporary directory, outside the repository, one per
entry at the entry's own relative path under that directory.

Two Quint binaries provide the full picture: 0.33.1 for the original 67 entries
and 0.34.0 for all 75. A sweep with 0.33.1 alone refuses the 0.34.0-only entries,
which is the intended signal rather than a failure.

### Reference figures

The figures below come from a run on 2026-11-26 over the entries in this
repository, with a quint-audit build that decodes the 0.34.0 declaration kinds.
A later build can move them. The command above is the reproducible part, and
these numbers are the shape to compare against.

| run | entries | exit 0 | exit 1 | could not run | findings |
|---|---|---|---|---|---|
| `lint`, Quint 0.34.0 | 75 | 60 | 14 | 1 | 3,649 |
| `lint`, Quint 0.33.1 | 75 | 55 | 11 | 9 | 3,482 |
| `lint`, Quint 0.34.0, original 67 only | 67 | 55 | 11 | 1 | 3,482 |

One entry cannot run under either version:
`corpus/third-party/cosmwasm-to-quint/lib/BoundedUInt.qnt`. It contains a
non-ASCII byte, which the audit's source gate refuses by design. It parses
under both Quint versions.

Under 0.33.1 the eight 0.34.0-only entries cannot run at all. They are the eight
extra could-not-run results in that row and their findings exist only in the
0.34.0 row. The 0.34.0 row over the original 67 entries is identical to the
0.33.1 row. The corpus is stable across the two releases. The difference
between the first two rows is the eight new entries.

## Tests

The suite checks the group counts, the digest table and the parse gate of
every entry at its declared minimum version.

Requirements: `janet`, `sh`, `sha256sum` and both Quint binaries. Point the
suite at them:

```sh
QUINT_0331=/path/to/quint-0.33.1 \
QUINT_0340=/path/to/quint-0.34.0 \
  test/run-tests.sh
```

Omit `QUINT_0340` when the `quint` on `PATH` reports 0.34.0. A missing 0.34.0
binary is a failure, not a skip. A full run takes about three minutes, most of
it parsing the larger entries twice.

## Provenance and licences

First-party and synthetic entries carry the AGPL-3.0-or-later licence of this
repository. Third-party entries carry their upstream licence. The provenance
row states the licence, and the licence file ships beside the entry:

- `corpus/third-party/chonkybft/`: Apache-2.0 OR MIT
- `corpus/third-party/cosmwasm-to-quint/`: Apache-2.0
- `corpus/third-party/quint/`: Apache-2.0

See `corpus/PROVENANCE.md` for the per-file record. It includes the move
history from quint-checktrace and the vocabulary change at first publication.

## Licence

AGPL-3.0-or-later. The full text is in `LICENSE`.

## AI assistance

The code in this repository was written with the assistance of a large language model and reviewed by its maintainer.
