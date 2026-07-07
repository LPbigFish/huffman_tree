# HuffmanTree

Huffman coding for Elixir. Encode strings to compact bitstrings, decode them back, and (de)serialize the tree itself.

## Installation

From GitHub:

```elixir
{:huffman_tree, git: "https://github.com/LPbigFish/huffman_tree.git"}
```

## Usage

```elixir
# Encode: returns bitstring + the tree needed to decode
{{bits, bit_count}, tree} = HuffmanTree.encode("hello world")

# Decode: needs bits, original bit count, and the tree
HuffmanTree.decode(bits, bit_count, tree)
#=> "hello world"

# Just build the tree
HuffmanTree.tree("aaaabbcccc")

# Serialize the tree to/from a bitstring (for storage/transmission)
packed = HuffmanTree.serialize(tree)
HuffmanTree.deserialize(packed)
```

## API

All public functions live in the `HuffmanTree` module:

| Function | Purpose |
| -------- | ------- |
| `HuffmanTree.tree/1` | Build a Huffman tree from text |
| `HuffmanTree.encode/1` | Encode text → `{bits, tree}` |
| `HuffmanTree.decode/3` | Decode bits + tree → text |
| `HuffmanTree.serialize/1` | Tree → bitstring |
| `HuffmanTree.deserialize/1` | Bitstring → tree |

`HuffmanTree.Tree` and `HuffmanTree.Node` are the underlying structs.
