defmodule AshCanonicalIdentityTest do
  use ExUnit.Case, async: false

  alias AshCanonicalIdentity.Test.{Post, PostTag, Repo}

  import ExUnit.CaptureLog

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
    test "list_by_title returns multiple posts (single column, list of tuples)" do
      Ash.create!(Post, %{title: "a"})
      Ash.create!(Post, %{title: "b"})
      Ash.create!(Post, %{title: "c"})

      result = Post.list_by_title!([{"a"}, {"c"}])

      assert length(result) == 2
      assert Enum.map(result, & &1.title) |> Enum.sort() == ["a", "c"]
    end

    test "list_by_title with single column list of values uses Eq" do
      Ash.create!(Post, %{title: "a"})
      Ash.create!(Post, %{title: "b"})
      Ash.create!(Post, %{title: "c"})

      # Single column can also use list of values
      log =
        capture_log(fn ->
          result = Post.list_by_title!(["a", "c"])

          assert length(result) == 2
          assert Enum.map(result, & &1.title) |> Enum.sort() == ["a", "c"]
        end)

      # Should NOT use IS NOT DISTINCT FROM (nils_distinct?: true by default)
      # Note: Ash optimizes single-column Eq+OR to = ANY, which is fine
      refute log =~ "IS NOT DISTINCT FROM"
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

    test "list_by_subtitle_category with nil values and nils_distinct?: false" do
      p1 = Ash.create!(Post, %{title: "p1", subtitle: "s1", category: "c1"})
      p2 = Ash.create!(Post, %{title: "p2", subtitle: nil, category: "c2"})
      p3 = Ash.create!(Post, %{title: "p3", subtitle: "s3", category: nil})
      p4 = Ash.create!(Post, %{title: "p4", subtitle: nil, category: nil})
      _p5 = Ash.create!(Post, %{title: "p5", subtitle: "s5", category: "c5"})

      # Search with nil values - uses IS NOT DISTINCT FROM
      log =
        capture_log(fn ->
          result =
            Post.list_by_subtitle_category!([
              {"s1", "c1"},
              {nil, "c2"},
              {"s3", nil},
              {nil, nil}
            ])

          assert length(result) == 4
          result_ids = Enum.map(result, & &1.id) |> Enum.sort()
          expected_ids = [p1.id, p2.id, p3.id, p4.id] |> Enum.sort()
          assert result_ids == expected_ids
        end)

      # Should use IS NOT DISTINCT FROM when there are nil values
      assert log =~ "IS NOT DISTINCT FROM"
    end

    test "list_by_subtitle_category with nils_distinct?: false uses Eq operator" do
      p1 = Ash.create!(Post, %{title: "p1", subtitle: "s1", category: "c1"})
      p2 = Ash.create!(Post, %{title: "p2", subtitle: "s2", category: "c2"})
      _p3 = Ash.create!(Post, %{title: "p3", subtitle: "s3", category: "c3"})

      # nils_distinct?: false uses Eq (=) when no nil values
      log =
        capture_log(fn ->
          result =
            Post.list_by_subtitle_category!([
              {"s1", "c1"},
              {"s2", "c2"}
            ])

          assert length(result) == 2
          result_ids = Enum.map(result, & &1.id) |> Enum.sort()
          expected_ids = [p1.id, p2.id] |> Enum.sort()
          assert result_ids == expected_ids
        end)

      # Should use IS NOT DISTINCT FROM (nils_distinct?: false always uses it)
      assert log =~ "IS NOT DISTINCT FROM"
    end

    test "list_by_subtitle_category raises when over max_list_size (multi-column)" do
      Ash.create!(Post, %{title: "p1", subtitle: nil, category: nil})

      values = Enum.map(1..101, fn i -> {nil, "c#{i}"} end)

      assert_raise ArgumentError,
                   "list_by action with OR expansion supports max 100 tuples, got 101",
                   fn ->
                     Post.list_by_subtitle_category!(values)
                   end
    end

    test "list_by_title does NOT enforce max_list_size (single-column with nils_distinct?: true)" do
      # Create 150 posts (exceeds default max_list_size of 100)
      Enum.each(1..150, fn i ->
        Ash.create!(Post, %{title: "post#{i}"})
      end)

      # Should NOT raise - single column with nils_distinct?: true uses = ANY optimization
      values = Enum.map(1..150, fn i -> "post#{i}" end)

      log =
        capture_log(fn ->
          result = Post.list_by_title!(values)
          assert length(result) == 150
        end)

      # Should use = ANY optimization (not OR expansion)
      assert log =~ "= ANY"
      refute log =~ " OR "
    end

    test "list_by_subtitle with single column and nil values (list of values)" do
      p1 = Ash.create!(Post, %{title: "p1", subtitle: "s1"})
      p2 = Ash.create!(Post, %{title: "p2", subtitle: nil})
      p3 = Ash.create!(Post, %{title: "p3", subtitle: "s3"})
      _p4 = Ash.create!(Post, %{title: "p4", subtitle: "s4"})

      # Single column with nil - passed as list of values
      log =
        capture_log(fn ->
          result = Post.list_by_subtitle!(["s1", nil, "s3"])

          assert length(result) == 3
          result_ids = Enum.map(result, & &1.id) |> Enum.sort()
          expected_ids = [p1.id, p2.id, p3.id] |> Enum.sort()
          assert result_ids == expected_ids
        end)

      # Should use IS NOT DISTINCT FROM when there are nil values
      assert log =~ "IS NOT DISTINCT FROM"
    end

    test "list_by_subtitle with single column (list of values) uses IS NOT DISTINCT FROM" do
      p1 = Ash.create!(Post, %{title: "p1", subtitle: "s1"})
      _p2 = Ash.create!(Post, %{title: "p2", subtitle: "s2"})
      p3 = Ash.create!(Post, %{title: "p3", subtitle: "s3"})

      # Single column with nils_distinct?: false uses IS NOT DISTINCT FROM
      log =
        capture_log(fn ->
          result = Post.list_by_subtitle!(["s1", "s3"])

          assert length(result) == 2
          result_ids = Enum.map(result, & &1.id) |> Enum.sort()
          expected_ids = [p1.id, p3.id] |> Enum.sort()
          assert result_ids == expected_ids
        end)

      # Should use IS NOT DISTINCT FROM (nils_distinct?: false)
      assert log =~ "IS NOT DISTINCT FROM"
    end

    test "list_by_subtitle raises when over max_list_size (single-column with nils_distinct?: false)" do
      # nils_distinct?: false requires OR expansion even for single column
      values = Enum.map(1..101, fn i -> "s#{i}" end)

      assert_raise ArgumentError,
                   "list_by action with OR expansion supports max 100 tuples, got 101",
                   fn ->
                     Post.list_by_subtitle!(values)
                   end
    end
  end

  describe "get_action with nil" do
    test "get_by_subtitle_category with nil values and nils_distinct?: false" do
      p1 = Ash.create!(Post, %{title: "p1", subtitle: nil, category: "c1"})

      result = Post.get_by_subtitle_category!(nil, "c1")
      assert result.id == p1.id
    end
  end
end
