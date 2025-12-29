defmodule AshCanonicalIdentity.ListPreparation do
  use Ash.Resource.Preparation

  @impl true
  def prepare(query, opts, _context) do
    attr_names = opts[:attr_names]
    where = opts[:where]

    values = Ash.Query.get_argument(query, :values)

    # Build OR filter: (a=1 AND b=2) OR (a=3 AND b=4)
    # values is a list of tuples: [{v1, v2}, {v3, v4}]
    or_filter =
      values
      |> Enum.map(fn value_tuple ->
        value_list = Tuple.to_list(value_tuple)

        Enum.zip(attr_names, value_list)
        |> Enum.map(fn {attr_name, value} ->
          %Ash.Query.Operator.Eq{left: %Ash.Query.Ref{attribute: attr_name}, right: value}
        end)
        |> Enum.reduce(fn expr, acc ->
          %Ash.Query.BooleanExpression{op: :and, left: acc, right: expr}
        end)
      end)
      |> Enum.reduce(fn expr, acc ->
        %Ash.Query.BooleanExpression{op: :or, left: acc, right: expr}
      end)

    filter =
      case where do
        nil -> or_filter
        w -> %Ash.Query.BooleanExpression{op: :and, left: w, right: or_filter}
      end

    Ash.Query.do_filter(query, filter)
  end
end
