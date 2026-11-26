# Corpus provenance

Authority for provenance and licensing of every corpus entry. Consumers
should treat this file as the deduplication and divergence detector. A file
listed here with a different digest has changed. A file present without a row
is an addition that never received provenance.

## Origin and move history

The repository author assembled the corpus to verify quint-audit 0.1.0 from
fixtures that quint-checktrace used. Its first public home was quint-checktrace,
under `test/corpus/corpus/`. quint-checktrace continues to carry the traces and
records that it generated from these entries.

This repository is the corpus's home from the split onward. The import was
byte-identical: the source is quint-checktrace at commit `0607c202` (release
tag `0.1.0` is `aded58ce` and carries the same corpus bytes), subtree
`5e1d8cbf24011f0aad0a78b7545289c7142c8f3b`. After the import, the git tree
object for `corpus/` was that same hash. Every digest below comes from the
imported copy.

This repository gained eight `synthetic/` entries with `min_quint` `0.34.0`
after the split. They appear under Synthetic 0.34 entries below, with the
shapes that each one covers.

## Publication scrub

The corpus as first published differs from the earlier working copy in 21
files. In those files a class label in a comment line reads `reference base`.
The published bytes are the authority. This repository imported those bytes
rather than the earlier working copy.

## Layout

| group | directory | entries |
|---|---|---|
| real | `real/` | 47 |
| third-party | `third-party/` | 18 |
| synthetic | `synthetic/` | 10 |

The repository author wrote two synthetic entries for quint-audit's first
publication. The same author wrote the other eight for this repository, and the
section below documents them.

Rules:

- Every `.qnt` file under this tree has exactly one row below.
- `origin_url` and `licence` are never empty. The corpus excludes every file
  that cannot carry both, and Rejected lists each one. Where an entry has no
  public source, the origin reads `first-party working copy, no public
  source`. The licence source is then this repository's `LICENSE`, a
  first-party grant by the same author.
- `first_party_third_party` is one of `first-party`, `third-party`,
  `synthetic`. Synthetic entries carry the AGPL-3.0-or-later licence of their
  origin project.
- `commit` is the commit that the file came from. An archive copy whose
  upstream commit does not contain the file names the archive commit and
  the upstream branch state.
- `q33_1_valid` is the validity-gate result at the pinned Quint 0.33.1
  (typecheck rc 0 and parse rc 0).
- `min_quint` is the oldest Quint release at which the entry parses.
  Entries written before 0.34.0 are valid at `0.33.1`. Entries that use the
  0.34.0 declaration kinds are valid at `0.34.0`, and 0.33.1 refuses them.
- `min_quint_gate` states the check that each entry gets at `min_quint`:
  `parse+typecheck`, or `parse only`. The `parse only` case is the one where an
  upstream typechecker rule refuses a shape that the parse tree carries (the
  parameterised property kinds).
- `sha256` is the digest of the file's bytes. The repository suite recomputes
  every digest and fails on a mismatch.
- The repository suite enforces the row-per-file rule.

| path | origin_url | repo | commit | licence | licence_source | first_party_third_party | model | standalone | q33_1_valid | min_quint | min_quint_gate | sha256 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| real/janet-num/specs/impl-resolution.qnt | https://github.com/jennystats/janet-num | jennystats/janet-num | b06e7d2b | AGPL-3.0-or-later | LICENSE (janet-num repo) | first-party | impl versus :num call resolution with dynamic switching | yes | yes | 0.33.1 | parse+typecheck | `b810a624bf7c96e5a41d4ab248714ec49f02f210278c0263b3b8d5cd6eb59da5` |
| real/janet-num/specs/syspath-heal.qnt | https://github.com/jennystats/janet-num | jennystats/janet-num | b06e7d2b | AGPL-3.0-or-later | LICENSE (janet-num repo) | first-party | syspath self-heal decision table | yes | yes | 0.33.1 | parse+typecheck | `7e3471c3cec85c5ec48863ce173f055e3243e11028592cdabc5eb4ecfc4fcfe8` |
| real/janet-query/specs/catalogue-partb.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | catalogue writer-identity lane | no, imports catalogue-record and catalogue-shapes | yes | 0.33.1 | parse+typecheck | `db4a194c758a259932fd37b93a522315efaa497f25dcd996d91ba7fa262c07b9` |
| real/janet-query/specs/catalogue-record.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | catalogue writer lane and present walk | no, imports catalogue-shapes | yes | 0.33.1 | parse+typecheck | `88ec7c90f06c1ea73733d12189e057bee9b5ee372032f747c865f73d7f6f4c99` |
| real/janet-query/specs/catalogue-shapes.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | catalogue shape lane and key-role table | yes | yes | 0.33.1 | parse+typecheck | `ca8c01fd47c78435369373942d6735e6dadf117dd9ec10c7e86a1bb61a5f644a` |
| real/janet-query/specs/intersection.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | registration and denial machine | yes | yes | 0.33.1 | parse+typecheck | `ff198e87f8d5552c1f6f2cd45eb8d5124f606c27a541b6ba14fe8333e6b185cb` |
| real/janet-query/specs/scope-model.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | reference scope machine | no, imports catalogue-record | yes | 0.33.1 | parse+typecheck | `04a8bf9c5447da1a1cf5314556836d92f18eb31103497fafabfde6a7a4aeaf3f` |
| real/janet-rayforce/specs/ownership.qnt | https://github.com/jennystats/janet-rayforce | jennystats/janet-rayforce | 4065b3b4 | AGPL-3.0-or-later | LICENSE (janet-rayforce repo) | first-party | ownership protocol over the Rayforce C ABI | yes | yes | 0.33.1 | parse+typecheck | `c80d2e9dec8002b8f243a3ac6f27509c62d817506f293818c61ddb3193d37304` |
| real/janet-rayforce/specs/packed-seam.qnt | first-party working copy, no public source | janet-rayforce (working copy) | 2a9a82e1 | AGPL-3.0-or-later | LICENSE (this repository, first-party grant) | first-party | packed f64 seam across the binding boundary | yes | yes | 0.33.1 | parse+typecheck | `e72e4cc6b837c28b6c5d9e56e9944bc0ea3883610357a934acc143f90df70933` |
| real/janet-stats/specs/ecdf-ks.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | ECDF and KS test contract | yes | yes | 0.33.1 | parse+typecheck | `fd6242521a6f93461a49132f7df1b8a45b2b01040206091ed88473ab0adb282c` |
| real/janet-stats/specs/iterative-solver.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | termination and error contract of iterative estimators | yes | yes | 0.33.1 | parse+typecheck | `d4f55fe1b3758b19231c04a278177ff5afb4efbf9c46dee1f27a36126abc2c0d` |
| real/janet-stats/specs/km-logrank.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | Kaplan-Meier and log-rank contract | yes | yes | 0.33.1 | parse+typecheck | `42d4330be6541d54b1cb71f4edeb20d098899f89c43d9ab894cae5e6e19056d7` |
| real/janet-stats/specs/mc-chain.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | MH and Gibbs bookkeeping contract | yes | yes | 0.33.1 | parse+typecheck | `ab7513741b5a25836ac222869333e8cf6972116a8de3b1b44c759bd9363d1094` |
| real/janet-stats/specs/perm-enumeration.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | two-lane permutation test contract | yes | yes | 0.33.1 | parse+typecheck | `ced16222d83544d85f6b041df6387f72aeaae0e6014eca2c7b38f77ecef452b3` |
| real/janet-viz/quint/geom.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | geometry margin and placement functions | yes | yes | 0.33.1 | parse+typecheck | `c52485c728c9ea1f893e6780614342aa158f776c16eb0b94fed236b0aef766b9` |
| real/janet-viz/quint/ir.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | display-list IR op enumeration with properties P1-P6 | yes | yes | 0.33.1 | parse+typecheck | `8a4a456ef887e10e178bc232814bcc22a52db109dbf8bb825b4247d8a965e9ad` |
| real/janet-viz/quint/surface-limb-calibration.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-limb-calibration.qnt line 2 | first-party | limb sweep instrument calibration | no, imports surface | yes | 0.33.1 | parse+typecheck | `616d8acedc4f98ded13474ded0996fd5829d48ab9a1262b87a5c701eea25427e` |
| real/janet-viz/quint/surface-trace.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 | first-party | shipped surface and witness specimens | yes | yes | 0.33.1 | parse+typecheck | `01bea05f77686ee4caa30e06168c1129b109a17501b3fc851d3973ef06908d58` |
| real/janet-viz/quint/surface.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | grammar surface limbs | yes | yes | 0.33.1 | parse+typecheck | `e828fe8155705bebc15154eca24ca2b8a45def00d446f1ee82f9f0a584b80aee` |
| real/janet-viz/quint/ticks.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | Wilkinson tick construction | yes | yes | 0.33.1 | parse+typecheck | `d6b8ce3b4f67f7effbaadfa8684ff7a45840a2b66be434bf9028c0a283a75c1f` |
| real/mark-task/specs/alias_commands.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | alias name and command registry | yes | yes | 0.33.1 | parse+typecheck | `a99eb4c636a09f0cfa7cad8243d6f467a5a292d817454ac6581a64158014f0be` |
| real/mark-task/specs/atomic_write.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | atomic write phases with an inline mutant module | yes | yes | 0.33.1 | parse+typecheck | `15a7bdefc1fba89589c11a0f12404d4dfc7d822f2d44b19266bb53525c2fdcc2` |
| real/mark-task/specs/configuration.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | configuration values | yes | yes | 0.33.1 | parse+typecheck | `890b855ecba9c8de9eaa39914e85b33e4dccfd7047257b286ecaa4a4dfb1347b` |
| real/mark-task/specs/conflict_resolution.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task status conflict resolution | yes | yes | 0.33.1 | parse+typecheck | `b89366e906469801c36d90b8e4d41b5978ffbdf1c6a80f42318c9485952fbe89` |
| real/mark-task/specs/data_storage.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task record storage | yes | yes | 0.33.1 | parse+typecheck | `aa9bc7662e191ea2e75e9adfd605d99005ba099ed9c4209ff4d7bd2d2fd772ea` |
| real/mark-task/specs/default_values.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | default status, priority, complexity and effort | yes | yes | 0.33.1 | parse+typecheck | `405c1eb31d1d557e11bff924c474ba37f9de6c7a971a0a99dc6986b81fd1be65` |
| real/mark-task/specs/desktop_notifications.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | due and overdue notification modes | yes | yes | 0.33.1 | parse+typecheck | `3078eafa76896f0ef744446e310e9f1fd56f535306a8a452e99bc0c925b85435` |
| real/mark-task/specs/interactive_mode.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | command history and responses | yes | yes | 0.33.1 | parse+typecheck | `ed8752bbc606d0896aa28e132c439c564cd4cd3c6cbda0f777299a208939ea69` |
| real/mark-task/specs/performance.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | due-window performance modes | yes | yes | 0.33.1 | parse+typecheck | `1b0fdaa4f56d49796ef7eb954f3868cacd976e91052dec0058a4affaedebf7ba` |
| real/mark-task/specs/recurring_tasks.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | recurrence periods and due-date rollover | yes | yes | 0.33.1 | parse+typecheck | `244ba96451c75daaafa76869a4baaca635828ed18be476b21fc9073563fd475d` |
| real/mark-task/specs/search_functionality.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task search over description and category | yes | yes | 0.33.1 | parse+typecheck | `d7ceb276fd9eaed4343b9d731df9b2c0fd9875f0e483f591c6a6c8e3db559ecf` |
| real/mark-task/specs/task_archiving.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | archive and restore tasks | yes | yes | 0.33.1 | parse+typecheck | `7a90e8ec319630d71e58aa6bb0fd531dea83f1dfef90f57f11679148da0b7e6d` |
| real/mark-task/specs/task_attributes.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task attribute set | yes | yes | 0.33.1 | parse+typecheck | `dbe6f1ad68f321ab94c9dd2b3c05640b26af20268f3646ef1179511c508b83b9` |
| real/mark-task/specs/task_counts.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task counts by status | yes | yes | 0.33.1 | parse+typecheck | `f6497ad6ad511d13f42ee806210a8d19b80dc2a7e8223b19ed1d2ab3fc9b9f8e` |
| real/mark-task/specs/task_management.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | create, update and complete tasks | yes | yes | 0.33.1 | parse+typecheck | `fb611ab2bc4b9ec4946897785474f1b85127877207093be84f0dbd8874de64e7` |
| real/mark-task/specs/task_views.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | filtered task views | yes | yes | 0.33.1 | parse+typecheck | `6b8dd57e479591e47a194825a4ca8f9d4e05717b2f3eaf8d3f570dc344c3fdc2` |
| real/mark-task/specs/undo_functionality.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | undo stack for task edits | yes | yes | 0.33.1 | parse+typecheck | `43f02e160f41f8bf69e744cb693a551e8490145ef3a79f168fe04ef62e48125c` |
| real/mark-task/specs/user_interface.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | interface rendering over status and priority | yes | yes | 0.33.1 | parse+typecheck | `052ca7f271550ed7be619168bc05210c9005ff84c18e90f14b4f80c96ba32209` |
| real/mark-task/specs/validation_error_handling.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | record and warning validation | yes | yes | 0.33.1 | parse+typecheck | `7de88403272b717ff4b5727be335ad46f2d4d21e264419eaedae4f9b3d8a43e2` |
| real/njuggle/icon-machine.qnt | first-party working copy, no public source | njuggle (working copy) | 67d555e7 | AGPL-3.0-or-later | LICENSE (this repository, first-party grant) | first-party | pane status-icon state machine and tab aggregation | yes | yes | 0.33.1 | parse+typecheck | `839f42315c482afad403cb2bbf6a5a738488b649b24f14b4df0e145258422c78` |
| real/njuggle/tab-visibility.qnt | first-party working copy, no public source | njuggle (working copy) | 67d555e7 | AGPL-3.0-or-later | LICENSE (this repository, first-party grant) | first-party | tab visibility decision table | yes | yes | 0.33.1 | parse+typecheck | `be8fc8adcfc8f5ebffdb529e8dacc8ad0a3dfe44f87f784384a5edec4e46b5a6` |
| real/omazing/specs/game-state-evidence/constant-check.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | maze constant checks against reviewed grids | no, imports ../game-state | yes | 0.33.1 | parse+typecheck | `fcf094e40257e460a03caac515f7dbc3ec747edf077084100871086f1168477c` |
| real/omazing/specs/game-state-evidence/properties.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | P3 premise checks | no, imports ../game-state | yes | 0.33.1 | parse+typecheck | `a1e6d2eb64e6a12112bca0d204d53edd78e6c172b798669101a0ec6f3ad22375` |
| real/omazing/specs/game-state-evidence/transitions.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | P2, P4, P5 and P6 as transition properties | no, imports ../game-state | yes | 0.33.1 | parse+typecheck | `a45a40fce961624c49432045778887de42123f3e1711f3f74803b69963589357` |
| real/omazing/specs/game-state.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | game-state movement contract | yes | yes | 0.33.1 | parse+typecheck | `c517f9b6f084999e17d338c2800780ce3f313edf57f4daabb04961244330ef91` |
| real/quint-audit/spec/qcalc.qnt | local repository, no remote configured | quint-audit | 8fc78e8 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | first-party | QP001 constant classification calculus | yes | yes | 0.33.1 | parse+typecheck | `7b515b8fc72b63c8c4834930d9d5329b0f4d0b6a8eebbd2f8f246413c2d85ba4` |
| real/quint-audit/spec/rundisc.qnt | local repository, no remote configured | quint-audit | 8fc78e8 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | first-party | C6 three-state run discipline | yes | yes | 0.33.1 | parse+typecheck | `650223b58b8932f0626afd377f58340b0a45ce1360b89e3610f9ee9448aad680` |
| synthetic/language-shapes.qnt | local repository, no remote configured | quint-audit | 5b2d23d5 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | synthetic | higher-order operators, three-deep records, 24-constructor enum | yes | yes | 0.33.1 | parse+typecheck | `26a3ddb3f8d701242a108b6aaa85073e4975f8f723eb2ee3b9dc3d99a64dcdc9` |
| synthetic/version-drift.qnt | local repository, no remote configured | quint-audit | 5b2d23d5 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | synthetic | conditionals in actions, nested record updates, nondet bindings, map and filter | yes | yes | 0.33.1 | parse+typecheck | `cf702dbbb0640ab8e9d7970e2f29a78b6639ebc6aee035d196d52064625bf15a` |
| third-party/chonkybft/defs.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/defs.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | ChonkyBFT shared definitions | yes | yes | 0.33.1 | parse+typecheck | `81c94268c8cee92d4f94e1b69a82688fd95d76de65aa598e1d18effd66e40192` |
| third-party/chonkybft/option.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/option.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | option type helpers | yes | yes | 0.33.1 | parse+typecheck | `941e6d1d6a713e9434774c2255cc313f29c1c4bcb60a757fbe14549af545c71c` |
| third-party/chonkybft/simplified/n6f1b1.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/simplified/n6f1b1.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | n=6, f=1 replica instance | no, imports replica | yes | 0.33.1 | parse+typecheck | `56e72bdda314b5c714365dd6d56bfb82898a2464ad8303227fc0d935109f864b` |
| third-party/chonkybft/simplified/replica.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/simplified/replica.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | ChonkyBFT simplified replica protocol | no, imports types, defs and option | yes | 0.33.1 | parse+typecheck | `415273a53f5392e25da97992aeb2afff238c8be3d52c81eeb2664af4d9ab66f9` |
| third-party/chonkybft/simplified/types.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/simplified/types.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | ChonkyBFT protocol types | no, imports option | yes | 0.33.1 | parse+typecheck | `392573426d6c94a6075bc1ae2712ba17946f97494fa5697aae6a53fc45d0d9c7` |
| third-party/cosmwasm-to-quint/lib/BoundedUInt.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/BoundedUInt.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | bounded unsigned integer module | yes | yes | 0.33.1 | parse+typecheck | `f9a1a3fb77aa2878fd89a2593a68e47bbadaf29cb70e313f85abd2adee7d4c33` |
| third-party/cosmwasm-to-quint/lib/bank.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/bank.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | bank module over cw_types | no, imports cw_types | yes | 0.33.1 | parse+typecheck | `7ac80696711a142014d7134947d8654c2d8445f6e4992b3ac9dc394b1fed8597` |
| third-party/cosmwasm-to-quint/lib/basicSpells.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/basicSpells.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | basic CosmWasm helpers | yes | yes | 0.33.1 | parse+typecheck | `70c8c220860fa37ab895884373d1465b5c0a04946612c331463f84ec5e1d4266` |
| third-party/cosmwasm-to-quint/lib/cw_types.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/cw_types.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | CosmWasm type definitions | no, imports basicSpells | yes | 0.33.1 | parse+typecheck | `4b3460dcc27e1418c9c6c2f7bd5df58a89ef9f8f0e3fd3157d06ceadf26e63f8` |
| third-party/cosmwasm-to-quint/lib/cw_utils.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/cw_utils.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | CosmWasm utility definitions | no, imports cw_types | yes | 0.33.1 | parse+typecheck | `1ce2058e9185d57f1e7f2ca9d5d8916b26ba2e5ea2c5f78cd360afea0abbf15b` |
| third-party/cosmwasm-to-quint/lib/messaging.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/messaging.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | CosmWasm message dispatch | no, imports cw_types, bank and basicSpells | yes | 0.33.1 | parse+typecheck | `0cb2d270abf7d47f8bf033b5b17ac7ea1ed96fd4f34befe7e44d0c7abfd551d2` |
| third-party/cosmwasm-to-quint/oaksecurity_cosmwasm_ctf_01_stubs.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/oaksecurity_cosmwasm_ctf_01_stubs.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | generated model stubs for the CTF-01 contract | no, imports the four lib modules | yes | 0.33.1 | parse+typecheck | `6f849c63f153fd960847e8fadacbed9d458fb07d7d16707968f069c2e8a17ce1` |
| third-party/quint/DiningPhilosophers5.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/DiningPhilosophers/DiningPhilosophers5.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | five-philosopher dining model | yes | yes | 0.33.1 | parse+typecheck | `0bc3c88a9b6bd905492ae02fe86caca478676f76200e60ac96e144a471141617` |
| third-party/quint/Paxos.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/Paxos/Paxos.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | Paxos consensus model | no, imports Voting | yes | 0.33.1 | parse+typecheck | `cffaa3557eb407149621011ee84a77f79c46b3adaa7d5e19c1205f4e476c85d3` |
| third-party/quint/Voting.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/Paxos/Voting.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | voting module used by Paxos | yes | yes | 0.33.1 | parse+typecheck | `b870adcb85b43651269d7ec33f4a63b197770ef4955ec063c733e3e2c58e8ba7` |
| third-party/quint/bank.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/cosmos/bank/bank.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | Cosmos bank module | yes | yes | 0.33.1 | parse+typecheck | `7a07b5982baf3fa71a68493aa5dd7f5f2cb8ed832dad8d0d6929ec4f228b8479` |
| third-party/quint/bankTest.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/cosmos/bank/bankTest.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | run tests for the bank module | no, imports bank | yes | 0.33.1 | parse+typecheck | `79653f7f908e3a1cb4dca5ab7b77910a6c77a0a6c6c9b28313fe9f3b1cbb20ac` |
| third-party/quint/two_phase_commit_modules.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/TwoPhaseCommit/two_phase_commit_modules.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | two-phase commit with module parameters | yes | yes | 0.33.1 | parse+typecheck | `b4b95a10d8b42aeb0f430d13ca71ae85ffb4616476ac129a912f13e5ee70b699` |

## Synthetic 0.34 entries

Eight entries written for this repository, each parse-valid under Quint
0.34.0. The seven with `parse+typecheck` also pass the 0.34.0 typechecker. The
parameterised entry is parse-only: 0.34.0 refuses parameters on the two
property kinds (QNT200), and the parse tree still carries them. All eight use
the declaration kinds added in 0.34.0. That is why 0.33.1 refuses them and why
each has a `min_quint` of `0.34.0`. Every one uses its declared kinds at a size
and declaration count comparable to the small real entries, not as a minimal
parse probe.

| path | origin_url | repo | commit | licence | licence_source | first_party_third_party | model | standalone | q33_1_valid | min_quint | min_quint_gate | sha256 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| synthetic/invariant-basics.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | queue capacity service with one invariant holding at init, one violated at init | yes | no | 0.34.0 | parse+typecheck | `117790c59880e2ae197d55f3d0a0b54a36ec6ec7dcbf160d4aa6dc0c5b86183f` |
| synthetic/imported-invariants.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | ledger invariants module imported unqualified, one imported invariant violated at init | yes | no | 0.34.0 | parse+typecheck | `3668fe904754b910a68fb7deb105bb748e23c3c2b84ab22f6e02a8918c1504fe` |
| synthetic/parameterised-properties.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | parameterised invariant and observation shapes beside a nullary pair | yes | no | 0.34.0 | parse only | `8237d2ff0d98fb8d58001479f119bae673bc264b654ef20ab6ae641f2a0fbfdc` |
| synthetic/observation-drive.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | observations true at init, reached by sampling, and unreachable under the step bound | yes | no | 0.34.0 | parse+typecheck | `f9c2e59dbf7fdef2427776101efd433476cb11ef6cac76f4c3e44257d96b8ec5` |
| synthetic/property-kinds.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | one property in val, invariant and observation spellings, plus constant properties | yes | no | 0.34.0 | parse+typecheck | `ce319cd0d34a384776dfacd9fed1b0d73e5dbf20139221db043424655ea79578` |
| synthetic/identifier-edges.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | invariant and observation as ordinary identifiers beside declarations of both kinds | yes | no | 0.34.0 | parse+typecheck | `b7bd6b5271bac7c3c17665a81b8f15886f9d035f8d07e0b276b49d04c655f495` |
| synthetic/temporal-kinds.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | temporal formulas beside an invariant and an observation in one module | yes | no | 0.34.0 | parse+typecheck | `1d20d0827aed4459ef18e38fd2843bca3022838a8b3a8e00b07313774521e43d` |
| synthetic/mixed-lifecycle.qnt | first-party working copy, no public source | Mimosa-Grove/quint-corpus | first commit | AGPL-3.0-or-later | LICENSE (this repository) | synthetic | work-queue lifecycle, 428 lines, mixed declaration kinds, trailing module doc comment | yes | no | 0.34.0 | parse+typecheck | `d0bd1169df3a83f8e9089176b76fc3cce1ab5893640daa2f4c7c1c4ad77abac1` |

Why each member exists:

- `invariant-basics` covers the invariant kind in both outcomes a checker
  distinguishes: a nullary invariant that holds at the initial state and one
  violated there. It also holds a constant tautology and uses invariants as
  values in a set.
- `imported-invariants` covers attribution: another module declares the
  violated invariant, and the file imports it unqualified. A checker then has
  to name the declaring module rather than the importing one. The same file
  uses imported and local invariants as values.
- `parameterised-properties` covers the parse-only shape: properties that
  take parameters parse, and the upstream typechecker refuses them. Tools
  that read the parse tree are the audience.
- `observation-drive` covers observation reachability in three classes: true
  in the initial state, reached by sampled traces and unreachable under the
  step bound.
- `property-kinds` covers coexistence: one property written as a val, an
  invariant and an observation, beside constant properties. One invariant
  survives the initial state and breaks on every action.
- `identifier-edges` covers the word-level edge the 0.34.0 release notes: the
  two kind names stay usable as ordinary identifiers beside declarations of
  the same kinds.
- `temporal-kinds` covers the adjacent shape: a temporal formula beside an
  invariant and an observation in one module. The corpus otherwise holds three
  temporal declarations in one third-party model.
- `mixed-lifecycle` covers size and mixture: a 428-line work-queue model
  combining actions, pure definitions, invariants, observations, two run
  tests and a trailing module doc comment.

## Rejected

Files excluded from the corpus, with the reason.

- `third-party/chonkybft/simplified/inductive.qnt` and
  `n6f1b1_inductive.qnt`: fail the 0.33.1 gate with QNT404
  `Name 'generate' not found`. `generate` is a removed builtin. A replacement
  changes sampling semantics, so the change is a port, not a mechanical fix,
  and the corpus drops both files.
- janet-query `specs/im/*.qnt` (five files): probe variants of
  `intersection.qnt`, one invariant changed per file.
- janet-query `specs/iv/*.qnt` (six files): 130-byte single-value wrappers
  around `intersection.qnt`.
- janet-viz `tmp/exp/minm*.qnt`, `probe8.qnt`, `probe9.qnt`: probe
  variants. `tmp/build/*.qnt`: scratch copies of the surface model.
- an earlier local copy of janet-query's
  `specs/catalogue-record.orig.qnt`: superseded copy of
  `catalogue-record.qnt`.
- local checkout copies of the published repos: the same bytes
  under a different checkout path, so the published-repo copy is the
  canonical row.
- mark-task `AtomicWriteMutant`: an inline mutant module inside
  `atomic_write.qnt`. The corpus keeps the file as the base model. The mutant
  module is not a separate corpus entry.
- OMazing `specs/game-state-evidence/gate-m1.qnt` through `gate-m6.qnt`,
  `mutants/*.qnt`, `tlc-*.qnt`, `probe-*.qnt`: mutants, templates and
  backend probes. `ctl-falsifiable.qnt` is a near-copy of
  `transitions.qnt` differing in one limb plus the module name.
- quint-audit `test/fixtures/specs/*.qnt`: single-expression probe
  fixtures. Probe-decoder specifications and mutants of
  `rundisc.qnt` and `qcalc.qnt`: same rule.
- an unrelated checkout supplied two MBT fixtures. The source tree does not
  record their origin commit, so they cannot receive a provenance row.


## Bundled licence texts

Byte digests of the licence texts that travel with the third-party
entries. The repository suite verifies them with the entry rows.

| path | sha256 |
|---|---|
| third-party/chonkybft/LICENSE-APACHE | `a6cba85bc92e0cff7a450b1d873c0eaa2e9fc96bf472df0247a26bec77bf3ff9` |
| third-party/chonkybft/LICENSE-MIT | `ce84bcb6aef2b659d20b30eaf4f8dee9f278862f1755e1e11c642f1ef4ad0b1d` |
| third-party/cosmwasm-to-quint/LICENSE | `c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4` |
| third-party/cosmwasm-to-quint/NOTICE | `4e301463d89c6e2988ad8d8597f481a617115b2fc8cb85759c8c70ee9e2c53e7` |
| third-party/quint/LICENSE | `0f8c4f9a99d4861ee62ade9a9526d09570844bdeab3e6bca500383d5ae7d9495` |
