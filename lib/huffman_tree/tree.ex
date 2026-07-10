defmodule HuffmanTree.Tree do
  @moduledoc """
  A Huffman tree.
  """
  alias HuffmanTree.Node

  @type t :: %__MODULE__{root: Node.t()}

  defstruct [:root]

  @spec new(Node.t()) :: t()
  def new(root) do
    %__MODULE__{root: root}
  end

  def get_counts(text) do
    text |> String.graphemes() |> Enum.frequencies()
  end

  defp build_nodes(counts) do
    counts |> Enum.map(fn {value, count} -> Node.new(count, value) end)
  end

  defp pair_nodes([node1, node2 | rest]) do
    new_node = Node.new(node1.weight + node2.weight, nil)
    new_node = %{new_node | left: node1, right: node2}
    [new_node | rest]
  end

  defp build_tree([root_node]), do: root_node

  defp build_tree(nodes) do
    nodes
    |> Enum.sort_by(fn node -> node.weight end)
    |> pair_nodes()
    |> build_tree()
  end

  @doc """
  Build a Huffman tree from a list of tuples containing characters and their frequencies.

    iex> HuffmanTree.Tree.from_text("aaaabbccccccccdddddd")
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
  @spec from_text(String.t()) :: t()
  def from_text(text) do
    root =
      text
      |> get_counts()
      |> build_nodes()
      |> case do
        # ponytail: empty text -> nil root; decode/3 returns "" for it.
        [] -> nil
        # ponytail: single distinct symbol gets a 1-bit code (<<0::1>>) so decode
        # can count symbols; a bare leaf would map to <<>> and loop forever.
        [single] -> wrap_single(single)
        nodes -> build_tree(nodes)
      end

    new(root)
  end

  defp wrap_single(node) do
    %{Node.new(node.weight, nil) | left: node, right: nil}
  end

  defp dfs_helper(nil, _path, acc), do: acc

  defp dfs_helper(node, path, acc) when is_bitstring(path) do
    acc =
      if node.value do
        Map.put(acc, node.value, path)
      else
        acc
      end

    Map.merge(
      dfs_helper(node.left, <<path::bitstring, 0::size(1)>>, acc),
      dfs_helper(node.right, <<path::bitstring, 1::size(1)>>, acc)
    )
  end

  @spec create_encoding_map(t()) :: %{String.t() => bitstring()}
  def create_encoding_map(tree) do
    dfs_helper(tree.root, <<>>, %{})
  end

  @spec readable_representation(%{String.t() => bitstring()}) :: %{String.t() => String.t()}
  def readable_representation(mappings) do
    Map.new(mappings, fn {key, bitstring} ->
      string_repr = for <<bit::1 <- bitstring>>, into: "", do: Integer.to_string(bit)

      {key, string_repr}
    end)
  end

  def serialize(tree) do
    bits = serialize_helper(tree.root)

    case rem(bit_size(bits), 8) do
      0 ->
        bits

      rem ->
        padding_size = 8 - rem
        <<bits::bitstring, 0::size(padding_size)>>
    end
  end

  defp serialize_helper(nil), do: <<>>

  defp serialize_helper(%{value: <<codepoint::utf8>>}) when not is_nil(codepoint) do
    <<1::size(1), codepoint::utf8>>
  end

  defp serialize_helper(%{value: nil, left: left, right: right}) do
    serialize_left = serialize_helper(left)
    serialize_right = serialize_helper(right)

    <<0::size(1), serialize_left::bitstring, serialize_right::bitstring>>
  end

  def deserialize(bitstring) do
    {root, _remaining_bits} = deserialize_helper(bitstring)
    new(root)
  end

  defp deserialize_helper(<<1::size(1), codepoint::utf8, rest::bitstring>>) do
    node = %Node{weight: 0, value: <<codepoint::utf8>>, left: nil, right: nil}
    {node, rest}
  end

  defp deserialize_helper(<<0::size(1), rest::bitstring>>) do
    {left_node, remaining_after_left} = deserialize_helper(rest)
    {right_node, remaining_after_right} = deserialize_helper(remaining_after_left)

    node = %Node{weight: 0, value: nil, left: left_node, right: right_node}
    {node, remaining_after_right}
  end
end
