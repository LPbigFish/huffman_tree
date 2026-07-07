defmodule HuffmanTree.Node do
  @moduledoc """
  A node in a Huffman tree.
  """
  @type t :: %__MODULE__{
          weight: non_neg_integer(),
          value: String.t() | nil,
          left: HuffmanTree.Node.t() | nil,
          right: HuffmanTree.Node.t() | nil
        }

  defstruct [:weight, :value, :left, :right]

  @doc """
    Create new `HuffmanTree.Node` struct with given weight and value.
  """
  @spec new(non_neg_integer(), String.t() | nil) :: HuffmanTree.Node.t()
  def new(weight, value) do
    %HuffmanTree.Node{weight: weight, value: value, left: nil, right: nil}
  end
end
