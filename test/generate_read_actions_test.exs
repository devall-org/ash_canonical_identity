defmodule AshCanonicalIdentity.GenerateReadActionsTest do
  use ExUnit.Case, async: true

  alias AshCanonicalIdentity.Test.{Post, ReadActionsDisabled}

  test "defaults to true and can be disabled per resource" do
    post_actions = Ash.Resource.Info.actions(Post) |> Enum.map(& &1.name)
    disabled_actions = Ash.Resource.Info.actions(ReadActionsDisabled) |> Enum.map(& &1.name)

    assert :get_by_title in post_actions
    assert :list_by_title in post_actions
    refute :get_by_name in disabled_actions
    refute :list_by_name in disabled_actions
    assert :get_by_category in disabled_actions
    assert :list_by_category in disabled_actions
  end
end
