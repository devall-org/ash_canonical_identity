defmodule AshCanonicalIdentityTest do
  use ExUnit.Case, async: false

  alias AshCanonicalIdentity.Test.{Post, PostTag, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  describe "get_action" do
    test "get_by_title returns single post" do
      post = Ash.create!(Post, %{title: "hello"})

      assert post.id == Post.get_by_title!("hello").id
      assert {:error, %Ash.Error.Invalid{}} = Post.get_by_title("world")
    end

    test "get_by_post_tag with belongs_to" do
      post = Ash.create!(Post, %{title: "test"})
      post_tag = Ash.create!(PostTag, %{post_id: post.id, tag: "elixir"})

      assert post_tag.id == PostTag.get_by_post_tag!(post.id, "elixir").id
      assert {:error, %Ash.Error.Invalid{}} = PostTag.get_by_post_tag(post.id, "other")
    end
  end

  describe "list_action" do
    test "list_by_title returns multiple posts" do
      Ash.create!(Post, %{title: "a"})
      Ash.create!(Post, %{title: "b"})
      Ash.create!(Post, %{title: "c"})

      result = Post.list_by_title!([{"a"}, {"c"}])

      assert length(result) == 2
      assert Enum.map(result, & &1.title) |> Enum.sort() == ["a", "c"]
    end

    test "list_by_post_tag with multiple columns" do
      post1 = Ash.create!(Post, %{title: "p1"})
      post2 = Ash.create!(Post, %{title: "p2"})

      pt1 = Ash.create!(PostTag, %{post_id: post1.id, tag: "t1"})
      _pt2 = Ash.create!(PostTag, %{post_id: post1.id, tag: "t2"})
      pt3 = Ash.create!(PostTag, %{post_id: post2.id, tag: "t1"})

      result =
        PostTag.list_by_post_tag!([
          {post1.id, "t1"},
          {post2.id, "t1"}
        ])

      assert length(result) == 2
      result_ids = Enum.map(result, & &1.id) |> Enum.sort()
      expected_ids = [pt1.id, pt3.id] |> Enum.sort()
      assert result_ids == expected_ids
    end
  end
end
