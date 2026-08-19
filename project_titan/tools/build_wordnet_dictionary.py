#!/usr/bin/env python3
"""Builds the TITAN Reader bundled dictionary from WordNet Release 3.0.

Source: WordNet 3.0, Copyright 2006 by Princeton University.
License: permission to use, copy, modify and distribute for any purpose
and without fee or royalty, provided the copyright notice and disclaimer
appear on all copies (see project_titan/apps/titan_reader/assets/dictionary/
manifest.json and docs/applications/titan_reader/DICTIONARY.md).

Input:  an extracted WordNet db directory (index.noun/verb/adj/adv and
        data.noun/verb/adj/adv files).
Output: apps/titan_reader/assets/dictionary/
        - manifest.json           source, version, license, attribution
        - headwords.json.gz       sorted headword list (prefix suggestions)
        - shards/<key>.json.gz    lemmas grouped by two-letter shard key

Only lemmas reachable from noun/verb/adjective/adverb senses are emitted.
Adjective satellite synsets (ss_type 's') are attributed to their head
synset's antonym pointers are resolved to concrete words.
"""

import argparse
import gzip
import json
import os
import re
import sys
from collections import defaultdict
from typing import Any

SynsetTable = dict[tuple[int, str], dict[str, Any]]
LemmaSenses = dict[str, list[tuple[int, str]]]

POS_FILES = ["noun", "verb", "adj", "adv"]
POS_LABELS = {
    "noun": "noun",
    "verb": "verb",
    "adj": "adjective",
    "adv": "adverb",
}

# Pointer records use single-letter pos codes; map them to data-file names.
POINTER_POS_TO_FILE = {"n": "noun", "v": "verb", "a": "adj", "s": "adj",
                       "r": "adv"}

GLOSS_EXAMPLE_RE = re.compile(r'"([^"]*)"')


def shard_key(word: str) -> str:
    """Two-character shard key for a normalized headword."""
    if len(word) >= 2 and word[0].isalpha() and word[1].isalpha():
        return word[:2]
    return "_" + (word[0] if word else "_")


def parse_data_file(path: str, synsets: SynsetTable) -> None:
    """Parses a data.pos file into synsets[(offset, pos)] = record."""
    with open(path, "r", encoding="cp1252") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line or line.startswith("  "):
                continue
            try:
                offset = int(line[0:8])
            except ValueError:
                continue
            head, _, gloss = line.partition(" | ")
            tokens = head.split()
            # tokens: offset, lexfilenum, ss_type, w_cnt, then word/lex_id
            # pairs, then p_cnt, then p_cnt pointer groups of four tokens.
            w_cnt = int(tokens[3], 16)
            idx = 4
            words = []
            for _ in range(w_cnt):
                words.append(tokens[idx].lower().replace("_", " "))
                idx += 2
            ptr_cnt = int(tokens[idx])
            idx += 1
            pointers = []
            for _ in range(ptr_cnt):
                group = tokens[idx : idx + 4]
                idx += 4
                if len(group) == 4:
                    pointers.append(group)
            definition = gloss
            examples = []
            if "; " in gloss:
                definition, rest = gloss.split("; ", 1)
                examples = GLOSS_EXAMPLE_RE.findall(rest)
            elif gloss.startswith(";"):
                definition = ""
                examples = GLOSS_EXAMPLE_RE.findall(gloss)
            synsets[(offset, path_pos(path))] = {
                "words": words,
                "pointers": pointers,
                "definition": definition.strip(),
                "examples": examples,
            }


def path_pos(path: str) -> str:
    return os.path.basename(path).split(".")[1]


def parse_index_file(path: str, lemma_senses: LemmaSenses) -> None:
    """Parses index.pos: lemma -> list of (offset, pos) sense targets."""
    pos = path_pos(path)
    with open(path, "r", encoding="cp1252") as handle:
        for line in handle:
            if not line or line.startswith("  "):
                continue
            parts = line.split()
            lemma = parts[0].lower().replace("_", " ")
            synset_cnt = int(parts[2])
            p_cnt = int(parts[3])
            offsets = parts[4 + p_cnt + 2 : 4 + p_cnt + 2 + synset_cnt]
            for off in offsets:
                lemma_senses[lemma].append((int(off), pos))


def resolve_antonyms(
    record: dict[str, Any], synsets: SynsetTable, word_index: int
) -> list[str]:
    """Resolves '!' pointers of one sense to concrete antonym words."""
    result = []
    for symbol, off, pos, srcdest in record["pointers"]:
        if symbol != "!":
            continue
        pos_key = POINTER_POS_TO_FILE.get(str(pos), str(pos))
        try:
            src = int(srcdest[:2], 16)
            dest = int(srcdest[2:], 16)
        except ValueError:
            continue
        if src != 0 and src - 1 != word_index:
            continue
        target = synsets.get((int(off), pos_key))
        if target is None:
            continue
        if dest == 0:
            result.extend(target["words"])
        elif dest - 1 < len(target["words"]):
            result.append(target["words"][dest - 1])
    return result


def build(db_dir: str, out_dir: str) -> None:
    synsets: SynsetTable = {}
    for pos in POS_FILES:
        parse_data_file(os.path.join(db_dir, "data." + pos), synsets)

    lemma_senses: LemmaSenses = defaultdict(list)
    for pos in POS_FILES:
        parse_index_file(os.path.join(db_dir, "index." + pos), lemma_senses)

    # word_index of a lemma inside each synset, for pointer scoping
    def word_index_in(record, lemma):
        try:
            return record["words"].index(lemma)
        except ValueError:
            return 0

    entries = {}
    for lemma, senses in lemma_senses.items():
        groups = {}
        for offset, pos in senses:
            record = synsets.get((offset, pos))
            if record is None:
                continue
            group = groups.setdefault(
                POS_LABELS[pos], {"definitions": [], "examples": [],
                                  "synonyms": set(), "antonyms": set()}
            )
            if record["definition"]:
                group["definitions"].append(record["definition"])
            group["examples"].extend(record["examples"])
            group["synonyms"].update(w for w in record["words"] if w != lemma)
            group["antonyms"].update(
                resolve_antonyms(record, synsets, word_index_in(record, lemma))
            )
        if not groups:
            continue
        entries[lemma] = {
            "w": lemma,
            "s": [
                {
                    "p": pos_label,
                    "d": group["definitions"],
                    "e": group["examples"][:8],
                    "y": sorted(group["synonyms"])[:24],
                    "a": sorted(group["antonyms"])[:12],
                }
                for pos_label, group in sorted(groups.items())
            ],
        }

    shards = defaultdict(dict)
    for lemma, entry in entries.items():
        shards[shard_key(lemma)][lemma] = entry

    os.makedirs(os.path.join(out_dir, "shards"), exist_ok=True)
    shard_manifest = []
    for key in sorted(shards):
        payload = json.dumps(
            shards[key], ensure_ascii=False, separators=(",", ":")
        ).encode("utf-8")
        rel = "shards/" + key + ".json.gz"
        with gzip.open(os.path.join(out_dir, rel), "wb", compresslevel=9) as gz:
            gz.write(payload)
        shard_manifest.append({"shard": key, "path": rel,
                               "words": len(shards[key])})

    headwords = sorted(entries.keys())
    headword_payload = json.dumps(
        headwords, ensure_ascii=False, separators=(",", ":")
    ).encode("utf-8")
    with gzip.open(os.path.join(out_dir, "headwords.json.gz"), "wb",
                   compresslevel=9) as gz:
        gz.write(headword_payload)

    license_text = open(os.path.join(db_dir, "LICENSE"), "r",
                        encoding="cp1252").read().strip()
    manifest = {
        "name": "TITAN Reader bundled dictionary",
        "version": 1,
        "source": "WordNet Release 3.0",
        "sourceUrl": "https://wordnet.princeton.edu/",
        "sourceVersion": "3.0",
        "copyright": "WordNet 3.0 Copyright 2006 by Princeton University. "
                     "All rights reserved.",
        "licenseSummary": "Free to use, copy, modify and distribute for any "
                          "purpose and without fee or royalty, provided the "
                          "copyright notice and disclaimer appear on all "
                          "copies.",
        "license": license_text,
        "attribution": "Definitions, examples, synonyms and antonyms derive "
                       "from WordNet(R) 3.0, a lexical database created by "
                       "the Cognitive Science Laboratory at Princeton "
                       "University.",
        "pronunciation": "not included; WordNet provides no phonetics",
        "wordCount": len(entries),
        "shardCount": len(shard_manifest),
        "shards": shard_manifest,
    }
    with open(os.path.join(out_dir, "manifest.json"), "w",
              encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)

    print(f"words={len(entries)} shards={len(shard_manifest)}")
    total = 0
    for name in os.listdir(out_dir):
        path = os.path.join(out_dir, name)
        if os.path.isfile(path):
            total += os.path.getsize(path)
    shard_total = sum(
        os.path.getsize(os.path.join(out_dir, "shards", f))
        for f in os.listdir(os.path.join(out_dir, "shards"))
    )
    print(f"disk_total_bytes={total + shard_total}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", required=True,
                        help="Directory containing WordNet data/index files")
    parser.add_argument("--out", required=True,
                        help="Output dictionary asset directory")
    args = parser.parse_args()
    build(args.db, args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
