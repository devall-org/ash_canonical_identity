defmodule AshCanonicalIdentity.ListPreparation do
  use Ash.Resource.Preparation

  @impl true
  def prepare(query, opts, _context) do
    attr_names = opts[:attr_names]
    where = opts[:where]
    nils_distinct? = opts[:nils_distinct?]
    max_list_size = opts[:max_list_size]

    values = Ash.Query.get_argument(query, :values)

    # Check max_list_size
    if length(values) > max_list_size do
      raise ArgumentError,
            "list_by action supports max #{max_list_size} tuples, got #{length(values)}"
    end

    # Build OR filter based on nils_distinct?
    or_filter = build_or_filter(attr_names, values, nils_distinct?)

    filter =
      case where do
        nil -> or_filter
        w -> %Ash.Query.BooleanExpression{op: :and, left: w, right: or_filter}
      end

    Ash.Query.do_filter(query, filter)
  end

  # Normalize value to list: tuple -> list, non-tuple -> [value]
  defp normalize_value(value) when is_tuple(value), do: Tuple.to_list(value)
  defp normalize_value(value), do: [value]

  # Build OR filter: (a=1 AND b=2) OR (a=3 AND b=4)
  defp build_or_filter(attr_names, values, nils_distinct?) do
    import Ash.Expr

    values
    |> Enum.map(fn value ->
      value_list = normalize_value(value)

      Enum.zip(attr_names, value_list)
      |> Enum.map(fn {attr_name, value} ->
        if nils_distinct? do
          %Ash.Query.Operator.Eq{left: %Ash.Query.Ref{attribute: attr_name}, right: value}
        else
          expr(fragment("? IS NOT DISTINCT FROM ?", ^ref(attr_name), ^value))
        end
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
