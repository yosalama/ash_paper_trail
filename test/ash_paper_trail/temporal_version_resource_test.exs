# SPDX-FileCopyrightText: 2022 ash_paper_trail contributors <https://github.com/ash-project/ash_paper_trail/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPaperTrail.TemporalVersionResourceTest do
  use ExUnit.Case, async: false

  alias AshPaperTrail.Test.Posts.TemporalVersionResourcePost

  @t1 ~U[2026-01-01 00:00:00.000000Z]
  @t2 ~U[2026-02-01 00:00:00.000000Z]
  @t3 ~U[2026-03-01 00:00:00.000000Z]

  setup do
    on_exit(fn ->
      Ash.DataLayer.Ets.stop(TemporalVersionResourcePost)
      Ash.DataLayer.Ets.stop(TemporalVersionResourcePost.Version)
    end)
  end

  test "the version relationships declare the temporal resource's period" do
    assert %{temporal_keys: {:valid_at, nil}} =
             Ash.Resource.Info.relationship(TemporalVersionResourcePost, :paper_trail_versions)

    assert %{temporal_keys: {nil, :valid_at}} =
             Ash.Resource.Info.relationship(TemporalVersionResourcePost.Version, :version_source)
  end

  test "each write records a version that relates back to the record" do
    post = TemporalVersionResourcePost.create!(%{subject: "first"}, as_of: @t1)
    TemporalVersionResourcePost.update!(post, %{subject: "second"}, as_of: @t2)

    versions =
      TemporalVersionResourcePost.Version
      |> Ash.read!()
      |> Ash.load!(version_source: Ash.Query.new(TemporalVersionResourcePost, as_of: @t2))

    assert versions |> Enum.map(& &1.changes.subject) |> Enum.sort() == ["first", "second"]

    assert Enum.all?(versions, &(&1.version_source.id == post.id))
  end

  test "a destroy that ends part of a version records the part it ended" do
    post = TemporalVersionResourcePost.create!(%{subject: "first"}, as_of: @t1)
    TemporalVersionResourcePost.destroy!(post, as_of: @t3)

    destroyed =
      TemporalVersionResourcePost.Version
      |> Ash.read!()
      |> Enum.find(&(&1.version_action_type == :destroy))

    assert %Ash.Range{lower: lower, upper: nil} = destroyed.changes.valid_at
    assert DateTime.compare(cast(lower), @t3) == :eq
  end

  defp cast(%DateTime{} = at), do: at
  defp cast(at) when is_binary(at), do: at |> DateTime.from_iso8601() |> elem(1)
end
