# SPDX-FileCopyrightText: 2022 ash_paper_trail contributors <https://github.com/ash-project/ash_paper_trail/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPaperTrail.Test.Posts.TemporalVersionResourcePost do
  @moduledoc """
  A temporal resource versioned in the default `:version_resource` mode.
  """

  use Ash.Resource,
    domain: AshPaperTrail.Test.Posts.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshPaperTrail.Resource],
    validate_domain_inclusion?: false

  ets do
    private? true
  end

  temporal do
    strategy :context
    attribute :valid_at
  end

  paper_trail do
    change_tracking_mode :snapshot
  end

  code_interface do
    define :create
    define :update
    define :destroy
  end

  actions do
    default_accept :*
    defaults [:read, :destroy, create: :*, update: :*]
  end

  attributes do
    uuid_primary_key :id

    attribute :subject, :string do
      public? true
    end
  end
end
