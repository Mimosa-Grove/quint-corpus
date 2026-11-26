# corpus_test.janet - the quint-corpus suite.
# Checks the corpus structure, the PROVENANCE digests, and the parse gate of
# every entry at its declared minimum Quint version. Core Janet only: the
# suite needs janet, a shell, sha256sum, and the Quint binaries.
#
# Environment:
#   QUINT_0331  path to the Quint 0.33.1 binary (default: quint on PATH)
#   QUINT_0340  path to the Quint 0.34.0 binary (default: quint on PATH when
#               its version reports 0.34, otherwise the run fails)
#
# Exit 1 on the first failed check after reporting it; a missing binary is a
# failure, never a skip.

(defn dir-of [p]
  (var last 0)
  (var i 0)
  (while (< i (length p))
    (when (= (p i) 47) (set last i))
    (++ i))
  (if (= last 0) "." (string/slice p 0 last)))

(def script-dir (dir-of ((dyn *args*) 0)))
(def root (dir-of script-dir))
(def prov-path (string root "/corpus/PROVENANCE.md"))

(var failures 0)

(defn fail [msg]
  (++ failures)
  (printf "FAIL %s" msg))

(defn pass [msg]
  (printf "ok %s" msg))

(defn sh-quote [s]
  (string "'" (string/replace-all "'" "'\\''" s) "'"))

(defn run-status [cmd]
  (def out (string "/tmp/quint-corpus-status-" (string (os/clock)) "-" (string (gensym))))
  (os/execute ["/bin/sh" "-c" (string cmd " > /dev/null 2>&1; echo $? > " (sh-quote out))]
              :p)
  (def code (string/trim (string (slurp out))))
  (os/execute ["/bin/rm" "-f" out] :p)
  code)

(defn command-output [cmd]
  (def out (string "/tmp/quint-corpus-out-" (string (os/clock)) "-" (string (gensym))))
  (os/execute ["/bin/sh" "-c" (string cmd " 2>&1 > " (sh-quote out))]
              :p)
  (def text (string (slurp out)))
  (os/execute ["/bin/rm" "-f" out] :p)
  text)

(defn walk [dir]
  (var acc @[])
  (defn- go [d]
    (each entry (os/dir d)
      (def full (string d "/" entry))
      (def st (os/stat full))
      (cond
        (and st (= (st :mode) :directory))
        (unless (= entry ".git") (go full))
        (and st (= (st :mode) :file))
        (array/push acc full))))
  (go dir)
  (sort acc))

(defn relative [path]
  (string/slice path (+ 1 (length root))))

(defn cells-of [line]
  (map string/trim (slice (string/split "|" line) 1 -1)))

# ---------------------------------------------------------------------------
# PROVENANCE rows
# ---------------------------------------------------------------------------

(def lines (string/split "\n" (string (slurp prov-path))))
(def entries @{})
(def licences @{})
(var section :entries)
(each line lines
  (cond
    (string/has-prefix? "## Synthetic 0.34 entries" line) (set section :entries)
    (string/has-prefix? "## Bundled licence texts" line) (set section :licences)
    (string/has-prefix? "## Rejected" line) (set section :other)
    (not (string/has-prefix? "|" line)) nil
    (string/has-prefix? "| path |" line) nil
    (string/has-prefix? "|---" line) nil
    (= section :entries)
    (do
      (def c (cells-of line))
      (when (and (>= (length c) 13) (string/has-suffix? ".qnt" (c 0)))
        (put entries (c 0) {:sha256 (c 12) :min_quint (c 10) :gate (c 11)})))
    (= section :licences)
    (do
      (def c (cells-of line))
      (when (and (>= (length c) 2) (not (empty? (c 0))))
        (put licences (c 0) (c 1))))))

# ---------------------------------------------------------------------------
# Structure
# ---------------------------------------------------------------------------

(def qnt-files (filter |(string/has-suffix? ".qnt" $) (walk (string root "/corpus"))))
(def on-disk (map relative qnt-files))
(var per-group @{"real" 0 "third-party" 0 "synthetic" 0})
(each path on-disk
  (def group (first (string/split "/" (string/replace-all "corpus/" "" path))))
  (when (get per-group group)
    (put per-group group (+ 1 (get per-group group)))))

(if (= (length qnt-files) 75)
  (pass "75 entries on disk")
  (fail (string "expected 75 entries, found " (length qnt-files))))

(each [group expected] (pairs {"real" 47 "third-party" 18 "synthetic" 10})
  (def got (get per-group group))
  (if (= got expected)
    (pass (string group " group has " expected " entries"))
    (fail (string group " group has " got " entries, expected " expected))))

(def row-paths (sort (keys entries)))
(def disk-paths (sort (map |(string/replace-all "corpus/" "" $) on-disk)))
(if (deep= row-paths disk-paths)
  (pass (string (length row-paths) " provenance rows match the disk"))
  (do
    (fail "provenance rows and disk entries differ")
    (each p disk-paths
      (unless (get entries p) (printf "  missing row: %s" p)))
    (each p row-paths
      (unless (index-of p disk-paths) (printf "  missing file: %s" p)))))

# ---------------------------------------------------------------------------
# Digests
# ---------------------------------------------------------------------------

(def rel-paths (sort (keys licences)))
(def all-paths (array/concat @[] (map |(string "corpus/" $) row-paths)
                             (map |(string "corpus/" $) rel-paths)))
(defn sha256-of [paths]
  (def cmd (string "sha256sum -- "
                   (string/join (map |(sh-quote (string root "/" $)) paths) " ")))
  (def text (command-output cmd))
  (def table @{})
  (each line (filter |(not (empty? $)) (string/split "\n" text))
    (def hash (string/slice line 0 64))
    (def path (string/trimr (string/slice line 66) " "))
    (put table (string/replace-all (string root "/") "" path) hash))
  table)

(def digests (sha256-of all-paths))
(var digest-bad 0)
(each [path meta] (pairs entries)
  (def want (string/replace-all "`" "" (meta :sha256)))
  (def got (get digests (string "corpus/" path)))
  (unless (= want got)
    (++ digest-bad)
    (fail (string "digest mismatch: " path))))
(each [path want-raw] (pairs licences)
  (def want (string/replace-all "`" "" want-raw))
  (def got (get digests (string "corpus/" path)))
  (unless (= want got)
    (++ digest-bad)
    (fail (string "digest mismatch: " path))))
(when (= digest-bad 0)
  (pass (string (+ (length entries) (length licences)) " digests match")))

# ---------------------------------------------------------------------------
# Parse gate
# ---------------------------------------------------------------------------

(def env (os/environ))
(defn env-or [name fallback]
  (def v (get env name))
  (if (and v (not (empty? v))) v fallback))

(def quint-0331 (env-or "QUINT_0331" "quint"))
(def version-output (command-output (string (sh-quote quint-0331) " --version")))
(def default-is-034 (string/has-prefix? "0.34" (string/trim version-output)))
(def quint-0340 (env-or "QUINT_0340" (if default-is-034 "quint" nil)))

(if quint-0340
  (pass (string "0.34 binary: " quint-0340))
  (fail "no Quint 0.34 binary: set QUINT_0340 (or put 0.34 first on PATH)"))

(defn parses? [binary path]
  (= "0" (run-status (string (sh-quote binary) " parse " (sh-quote (string root "/corpus/" path))
                             " --out /dev/null"))))

(var ok-033 0)
(var ok-034 0)
(var refused-033 0)
(each [path meta] (pairs entries)
  (cond
    (= (meta :min_quint) "0.33.1")
    (do
      (if (parses? quint-0331 path)
        (++ ok-033)
        (fail (string "0.33.1 parse refused: " path)))
      (when quint-0340
        (if (parses? quint-0340 path)
          (++ ok-034)
          (fail (string "0.34.0 parse refused pre-0.34 entry: " path)))))
    (= (meta :min_quint) "0.34.0")
    (do
      (when quint-0340
        (if (parses? quint-0340 path)
          (++ ok-034)
          (fail (string "0.34.0 parse refused: " path))))
      (if (parses? quint-0331 path)
        (fail (string "0.33.1 accepted a 0.34-only entry: " path))
        (++ refused-033)))
    (fail (string "unknown min_quint: " path))))

(pass (string ok-033 " pre-0.34 entries parse at 0.33.1"))
(when quint-0340
  (pass (string ok-034 " entries parse at 0.34.0")))
(pass (string refused-033 " 0.34-only entries are refused by 0.33.1"))

(if (= ok-033 67)
  (pass "0.33.1 gate covered all 67 pre-0.34 entries")
  (fail (string "0.33.1 gate covered " ok-033 " of 67 pre-0.34 entries")))
(when quint-0340
  (if (= ok-034 75)
    (pass "0.34.0 gate covered all 75 entries")
    (fail (string "0.34.0 gate covered " ok-034 " of 75 entries"))))
(if (= refused-033 8)
  (pass "0.33.1 refusal covered all 8 0.34-only entries")
  (fail (string "0.33.1 refusal covered " refused-033 " of 8 0.34-only entries")))

(when (= failures 0)
  (print (string "END-OF-SUITE pass entries=" (length entries))))
(unless (= failures 0)
  (printf "END-OF-SUITE fail failures=%d" failures)
  (os/exit 1))
