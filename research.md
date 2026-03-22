# Code Clone Detection: Research Findings

## Clone Taxonomy

The standard classification (Roy, Cordy, Koschke — SCP 2009; Bellon et al. — IEEE TSE 2007):

| Type | Name | Description |
|------|------|-------------|
| Type 1 | Exact | Identical except whitespace/comments |
| Type 2 | Renamed/Parameterized | Identifiers, literals, types renamed consistently |
| Type 3 | Gapped/Near-miss | Statements added, removed, or changed |
| Type 4 | Semantic | Different syntax, same behavior (undecidable in general) |

## Detection Technique Families

### Text-Based
- Line/string matching after minimal normalization
- Johnson 1993 (fingerprinting), Ducasse/Rieger/Demeyer 1999 (Duploc dot plots)
- Only Type 1. Language-independent, trivial, fast, brittle.

### Token-Based
- Lex into tokens, strip identifiers/literals to canonical forms, match subsequences
- **CCFinder** (Kamiya 2002): suffix-tree on token stream
- **Baker's Dup** (1995): parameterized string matching (p-match)
- **CP-Miner** (Li 2006): frequent subsequence mining
- **SourcererCC** (Sajnani 2016): bag-of-tokens with overlap similarity, scaled to 250 MLOC
- Types 1, 2, some 3. Fast, scalable.

### AST-Based
- Parse into AST, find similar/identical subtrees
- **CloneDR** (Baxter 1998): bottom-up subtree hashing, near-miss via similarity threshold
- **DECKARD** (Jiang 2007): characteristic vectors (count node-type occurrences per subtree), cluster via LSH
- **Abstract Syntax Suffix Trees** (Koschke 2006): serialize AST, build suffix tree — linear time
- **NiCad** (Cordy/Roy 2008): parse + pretty-print + normalize + LCS comparison
- **Clone Digger** (Bulychev/Minea 2008): anti-unification on ASTs
- Types 1, 2, 3. More robust than token-based, slower due to parsing.

### PDG-Based (Program Dependence Graphs)
- Nodes = statements, edges = data/control dependencies. Clone = isomorphic subgraph.
- Komondoor/Horwitz 2001: program slicing on PDGs, finds non-contiguous and reordered clones
- Krinke 2001: k-length patch matching
- Types 1–3, some Type 4. Expensive (NP-complete subgraph isomorphism). Hard to scale.

### Metric-Based
- Compute metric vectors per function (cyclomatic complexity, params, LOC, fan-in/fan-out, etc.)
- Mayrand/Leblanc/Merlo 1996, Kontogiannis 1996
- Fast but high false-positive rate. Function-level granularity only.

### Machine Learning / Deep Learning
- code2vec (Alon 2019): AST path embeddings
- CodeBERT, GraphCodeBERT: transformer embeddings for code
- LLMs (GPT-4): strong on Type 4 with chain-of-thought prompting
- Siamese networks for hard-to-detect clones

### Semantic
- Symbolic execution, input-output testing, model checking
- HyClone (2025): LLM screening + execution-based validation
- Targets Type 4. Least scalable.

## Key Algorithms for Tree/S-Expression Clone Detection

### Subtree Hashing (CloneDR)
1. Traverse bottom-up, `hash(node) = f(type, hash(child₁), ..., hash(childₙ))`
2. Group subtrees by hash bucket
3. Same bucket = Type 1 candidates
4. Near-miss: compare across nearby buckets with similarity threshold
- O(n) for hashing, O(k²) per bucket

### Characteristic Vectors + Clustering (DECKARD)
1. Per subtree, count occurrences of each node type → vector in ℝᵈ
2. Cluster vectors via Locality-Sensitive Hashing (Euclidean distance)
3. Same cluster = clone candidates
- Naturally handles Type 3 (small changes → small vector shifts)

### Anti-Unification (Clone Digger)
- Given t₁, t₂, compute most specific generalization (least general term where both are instances via substitution)
- `(+ x (* y 3))` and `(+ a (* b 3))` → `(+ ?₁ (* ?₂ 3))` with 2 holes
- Similarity = 1 - (holes / total-nodes)
- Directly handles Type 3 (few holes = near-miss clone)

### Tree Edit Distance (Zhang-Shasha 1989)
- Min insertions/deletions/relabelings to transform one tree into another
- If distance / max(|t₁|, |t₂|) < threshold → clone
- O(n₁ · n₂ · min(depth₁, leaves₁) · min(depth₂, leaves₂))

### Tree Isomorphism (AHU — Aho, Hopcroft, Ullman)
- Canonical encoding computed bottom-up from sorted children encodings
- Two trees isomorphic iff same canonical encoding
- O(n log n)

### Abstract Syntax Suffix Trees (Koschke 2006)
- Serialize AST via pre-order traversal → token sequence
- Build generalized suffix tree
- Repeated substrings = repeated subtrees
- O(n) time and space

### Tree Kernels
- Subtree Kernel (STK), Subset Tree Kernel (SSTK), Partial Tree Kernel (PTK)
- Count common substructures between trees
- Used with SVMs for clone classification

## The Lisp / S-Expression Advantage

In Clojure/Lisp, **code IS the AST**. `read-string` gives you the tree directly — no parser needed. This means:

1. **Subtree hashing** = recursive hash over nested lists
2. **Anti-unification** = direct recursive algorithm on lists
3. **Tree edit distance** = operates on native data structures
4. **Normalization** = `clojure.walk/postwalk`
5. **Subtree enumeration** = `tree-seq coll? seq`

Uniform syntax (s-expressions) means structurally identical computations always have structurally identical representations. No syntactic sugar ambiguity.

Macro expansion (via `tools.analyzer.jvm`) can expose the actual executed code for deeper analysis.

## Clojure-Specific Tooling

| Tool | What it does | Clone detection? |
|------|-------------|-----------------|
| clj-kondo | Static linting | No |
| eastwood | Runtime linting | No |
| kibit | Idiomatic rewrites via core.logic | No (pattern search, not discovery) |
| grasp (borkdude) | Grep s-expressions with spec patterns | Finds known patterns, doesn't discover unknowns |
| rewrite-clj | CST with whitespace preservation | Foundation for location-aware analysis |
| tools.analyzer.jvm | Full semantic AST with macro expansion | Richest representation, heaviest dependency |
| doppelganger | Clojure duplicate detection | Abandoned (2015, 1 commit) |

## Practical Parameters

- **Minimum clone size**: 5-6 lines, 50-100 tokens, or 20-50 AST nodes
- **Similarity threshold**: 0.70–0.90 for Type 3
- **Normalization choices**: identifier abstraction, literal abstraction, type abstraction
- **Granularity**: function-level, block-level, statement-level, file-level
- **Scalability filters**: prefix filtering, length filtering, token frequency filtering

## Key References

- Roy, Cordy, Koschke: "Comparison and evaluation of code clone detection techniques and tools" (SCP 2009)
- Bellon et al.: "Comparison and Evaluation of Clone Detection Tools" (IEEE TSE 2007)
- Baxter et al.: "Clone Detection Using Abstract Syntax Trees" (ICSM 1998)
- Kamiya et al.: "CCFinder" (IEEE TSE 2002)
- Jiang et al.: "DECKARD" (ICSE 2007)
- Sajnani et al.: "SourcererCC" (ICSE 2016)
- Cordy, Roy: "NiCad" (ICPC 2008)
- Bulychev, Minea: "Duplicate Code Detection Using Anti-Unification" (SYRCoSE 2008)
- Koschke et al.: "Abstract Syntax Suffix Trees" (WCRE 2006)
- Baker: "Parameterized Duplication in Strings" (SIAM J. Comp. 1997)
- Li et al.: "CP-Miner" (IEEE TSE 2006)
- Komondoor, Horwitz: "Using Slicing to Identify Duplication" (SAS 2001)
