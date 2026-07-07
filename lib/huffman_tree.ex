defmodule HuffmanTree do
  @moduledoc """
  Public API for Huffman coding over `HuffmanTree.Tree`.
  """

  alias HuffmanTree.Tree

  @doc """
  Build a Huffman tree from a list of tuples containing characters and their frequencies.

    iex> HuffmanTree.tree("aaaabbccccccccdddddd")
    %HuffmanTree.Tree{
      root: %HuffmanTree.Node{
        weight: 20,
        value: nil,
        left: %HuffmanTree.Node{weight: 8, value: "c", left: nil, right: nil},
        right: %HuffmanTree.Node{
          weight: 12,
          value: nil,
          left: %HuffmanTree.Node{
            weight: 6,
            value: nil,
            left: %HuffmanTree.Node{weight: 2, value: "b", left: nil, right: nil},
            right: %HuffmanTree.Node{weight: 4, value: "a", left: nil, right: nil}
          },
          right: %HuffmanTree.Node{weight: 6, value: "d", left: nil, right: nil}
        }
      }
    }
  """
  @spec tree(String.t()) :: Tree.t()
  def tree(text) do
    Tree.from_text(text)
  end

  @spec encode(binary()) :: {{bitstring(), non_neg_integer()}, Tree.t()}
  def encode(text) do
    tree = tree(text)
    encoding_map = Tree.create_encoding_map(tree)

    {encode_helper(text, encoding_map), tree}
  end

  defp encode_helper(text, encoding_map) do
    bit_list =
      text
      |> String.graphemes()
      |> Stream.map(&Map.get(encoding_map, &1))

    raw_bitstring = for bits <- bit_list, into: <<>>, do: bits

    bit_size = bit_size(raw_bitstring)

    remainder = rem(bit_size, 8)

    if remainder == 0 do
      {raw_bitstring, bit_size}
    else
      padding_size = 8 - remainder
      padded_bitstring = <<raw_bitstring::bitstring, 0::size(padding_size)>>
      {padded_bitstring, bit_size}
    end
  end

  @doc """
  Decode a bitstring using the provided Huffman tree.
  """
  @spec decode(bitstring(), non_neg_integer(), Tree.t()) :: binary()
  def decode(bitstring, bit_size, tree) do
    decode_helper(bitstring, bit_size, tree.root, tree.root, [])
  end

  defp decode_helper(_bitstring, 0, _current_node, _root, acc) do
    acc |> Enum.reverse() |> Enum.join()
  end

  defp decode_helper(bitstring, remaining_bits, %{value: value}, root, acc)
       when not is_nil(value) do
    decode_helper(bitstring, remaining_bits, root, root, [value | acc])
  end

  defp decode_helper(<<0::1, rest::bitstring>>, remaining_bits, %{left: left_node}, root, acc) do
    decode_helper(rest, remaining_bits - 1, left_node, root, acc)
  end

  defp decode_helper(<<1::1, rest::bitstring>>, remaining_bits, %{right: right_node}, root, acc) do
    decode_helper(rest, remaining_bits - 1, right_node, root, acc)
  end

  @doc """
    Serialize a Huffman tree into a bitstring.
  """
  @spec serialize(Tree.t()) :: bitstring()
  def serialize(tree) do
    Tree.serialize(tree)
  end

  @doc """
    Deserialize a bitstring into a Huffman tree.
  """
  @spec deserialize(bitstring()) :: Tree.t()
  def deserialize(bitstring) do
    Tree.deserialize(bitstring)
  end
end
