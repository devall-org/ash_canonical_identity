defmodule AshCanonicalIdentity.ListPreparation do
  use Ash.Resource.Preparation

  @impl true
  def prepare(query, opts, _context) do
    attr_names = opts[:attr_names]
    where = opts[:where]
    nils_distinct? = opts[:nils_distinct?]

    values = Ash.Query.get_argument(query, :values)

    # Check if any value contains nil
    has_nil? =
      values
      |> Enum.any?(fn value ->
        value |> normalize_value() |> Enum.any?(&is_nil/1)
      end)

    use_in? = nils_distinct? or not has_nil?

    filter =
      if use_in? do
        build_in_filter(attr_names, values)
      else
        if length(values) > 100 do
          raise ArgumentError,
                "nils_distinct?: false with nil values supports max 100 tuples, got #{length(values)}"
        end

        build_or_distinct_filter(attr_names, values)
      end

    filter =
      case where do
        nil -> filter
        w -> %Ash.Query.BooleanExpression{op: :and, left: w, right: filter}
      end

    Ash.Query.do_filter(query, filter)
  end

  # Normalize value to list: tuple -> list, non-tuple -> [value]
  defp normalize_value(value) when is_tuple(value), do: Tuple.to_list(value)
  defp normalize_value(value), do: [value]

  # IN approach: (a, b) IN ((1, 2), (3, 4))
  defp build_in_filter(attr_names, values) do
    values
    |> Enum.map(fn value ->
      value_list = normalize_value(value)

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
  end

  # OR + IS NOT DISTINCT FROM approach
  defp build_or_distinct_filter(attr_names, values) do
    import Ash.Expr

    values
    |> Enum.map(fn value ->
      value_list = normalize_value(value)

      Enum.zip(attr_names, value_list)
      |> Enum.map(fn {attr_name, value} ->
        expr(fragment("? IS NOT DISTINCT FROM ?", ^ref(attr_name), ^value))
      end)
      |> Enum.reduce(fn expr, acc ->
        %Ash.Query.BooleanExpression{op: :and, left: acc, right: expr}
      end)
    end)
    |> Enum.reduce(fn expr, acc ->
      %Ash.Query.BooleanExpression{op: :or, left: acc, right: expr}
    end)
  end
end
