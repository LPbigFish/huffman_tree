defmodule HuffmanTreeTest do
  use ExUnit.Case, async: true
  doctest HuffmanTree
  doctest HuffmanTree.Tree

  alias HuffmanTree.{Node, Tree}

  describe "tree/1" do
    test "builds tree wrapping a root node" do
      tree = HuffmanTree.tree("aaab")
      %Tree{root: %Node{}} = tree
    end

    test "root weight equals total grapheme count" do
      text = "aaaabbccccccccdddddd"
      tree = HuffmanTree.tree(text)
      assert tree.root.weight == String.graphemes(text) |> length()
    end

    test "internal nodes carry nil value, leaves carry graphemes" do
      tree = HuffmanTree.tree("ab")
      assert is_binary(tree.root.value) or is_nil(tree.root.value)
      leaves = collect_leaves(tree.root)
      assert Enum.all?(leaves, &(&1.value != nil))
      assert Enum.all?(leaves, &(&1.left == nil and &1.right == nil))
    end

    test "empty string yields nil-root tree" do
      assert %Tree{root: nil} = HuffmanTree.tree("")
    end
  end

  describe "encode/1 shape" do
    test "returns {{bitstring, bit_count}, tree}" do
      {{bits, count}, %Tree{} = _tree} = HuffmanTree.encode("hello")
      assert is_bitstring(bits)
      assert is_integer(count) and count >= 0
    end

    test "emitted bitstring is byte-aligned (multiple of 8 bits)" do
      {{bits, _count}, _tree} = HuffmanTree.encode("round trip please")
      assert bit_size(bits) |> rem(8) == 0
    end

    test "count tracks real bits, not padded size" do
      {{bits, count}, _tree} = HuffmanTree.encode("ab")
      assert count < bit_size(bits) or count == bit_size(bits)
    end
  end

  describe "encode/decode round trip" do
    @inputs [
      "",
      "a",
      "aaaa",
      "ab",
      "aaab",
      "hello world",
      "the quick brown fox jumps over the lazy dog",
      String.duplicate("a", 100) <> String.duplicate("b", 50) <> "c",
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef",
      "mississippi river"
    ]

    for text <- @inputs do
      @text text
      test "round trips: #{String.slice(text, 0, 24)}" do
        {{bits, count}, tree} = HuffmanTree.encode(@text)
        assert HuffmanTree.decode(bits, count, tree) == @text
      end
    end

    test "decoded result matches regardless of padding bits" do
      {{bits, count}, tree} = HuffmanTree.encode("abc")
      # flip trailing padding bits; real bits untouched
      padded_flipped = flip_padding(bits, count)
      assert HuffmanTree.decode(padded_flipped, count, tree) == "abc"
    end
  end

  describe "create_encoding_map/1" do
    test "maps every distinct grapheme to a unique bitstring code" do
      text = "aaaabbcccc"
      map = HuffmanTree.tree(text) |> Tree.create_encoding_map()
      graphemes = text |> String.graphemes() |> MapSet.new()
      assert MapSet.new(Map.keys(map)) == graphemes
    end

    test "codes form a prefix-free set" do
      map = HuffmanTree.tree("prefix free check please") |> Tree.create_encoding_map()
      codes = Map.values(map)

      for c <- codes, d <- codes, c != d do
        refute String.starts_with?(to_bitstring_str(c), to_bitstring_str(d))
        refute String.starts_with?(to_bitstring_str(d), to_bitstring_str(c))
      end
    end
  end

  describe "readable_representation/1" do
    test "turns bitstring codes into 0/1 strings" do
      map = HuffmanTree.tree("ab") |> Tree.create_encoding_map()
      readable = Tree.readable_representation(map)

      assert Map.values(readable) |> Enum.all?(&String.match?(&1, ~r/^[01]+$/))
    end
  end

  describe "serialize/deserialize" do
    test "round trip preserves decode behavior (ASCII)" do
      text = "ascii round trip works"
      {{bits, count}, tree} = HuffmanTree.encode(text)
      packed = HuffmanTree.serialize(tree)
      rebuilt = HuffmanTree.deserialize(packed)

      assert HuffmanTree.decode(bits, count, rebuilt) == text
    end

    test "round trip preserves decode behavior (non-ASCII, single-codepoint graphemes)" do
      text = "café résumé naïve"
      {{bits, count}, tree} = HuffmanTree.encode(text)
      packed = HuffmanTree.serialize(tree)
      rebuilt = HuffmanTree.deserialize(packed)

      assert HuffmanTree.decode(bits, count, rebuilt) == text
    end

    test "serialized output is byte-aligned bitstring" do
      packed = HuffmanTree.tree("align me") |> HuffmanTree.serialize()
      assert is_bitstring(packed)
      assert bit_size(packed) |> rem(8) == 0
    end

    test "deserialize yields a Tree struct with Node root" do
      packed = HuffmanTree.tree("struct check") |> HuffmanTree.serialize()
      %Tree{root: %Node{}} = HuffmanTree.deserialize(packed)
    end
  end

  describe "Tree.get_counts/1" do
    test "returns grapheme frequencies" do
      assert Tree.get_counts("aaabbc") == %{"a" => 3, "b" => 2, "c" => 1}
    end

    test "empty string yields empty map" do
      assert Tree.get_counts("") == %{}
    end
  end

  describe "Node.new/2" do
    test "builds leaf node with nil children" do
      node = Node.new(5, "x")
      assert %Node{weight: 5, value: "x", left: nil, right: nil} == node
    end

    test "accepts nil value for internal nodes" do
      assert %Node{weight: 0, value: nil} = Node.new(0, nil)
    end
  end

  defp collect_leaves(%Node{value: v, left: nil, right: nil}) when not is_nil(v),
    do: [%Node{value: v}]

  defp collect_leaves(%Node{left: l, right: r}), do: collect_leaves(l) ++ collect_leaves(r)
  defp collect_leaves(nil), do: []

  defp to_bitstring_str(bits) do
    for <<b::1 <- bits>>, into: "", do: Integer.to_string(b)
  end

  defp flip_padding(bits, count) do
    total = bit_size(bits)
    pad = total - count

    if pad == 0 do
      bits
    else
      <<real::size(count), _pad::size(pad)>> = bits
      <<real::size(count), 0xFFFFFFFF::size(pad)>>
    end
  end
end
