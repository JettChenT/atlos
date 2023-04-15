defmodule Platform.Material.MediaVersion do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Material.Media

  @derive {Jason.Encoder, except: [:__meta__, :client_name, :file_location, :media]}
  schema "media_versions" do
    field(:scoped_id, :integer)

    field(:upload_type, Ecto.Enum, values: [:user_provided, :direct], default: :user_provided)
    field(:source_url, :string)
    field(:hashes, :map, default: %{})

    @primary_key {:id, :binary_id, autogenerate: true}
    embeds_many :artifacts, Platform.Material.MediaVersionArtifact do
      field(:file_location, :string)
      field(:thumbnail_location, :string)
      field(:file_hash_sha256, :string)
      field(:file_size, :integer)
      field(:mime_type, :string)
      field(:metadata, :map, default: %{})
      field(:type, Ecto.Enum, values: [:webarchive, :media, :upload, :other], default: :other)
      timestamps()
    end

    field(:status, Ecto.Enum, values: [:pending, :complete, :error], default: :complete)
    field(:visibility, Ecto.Enum, default: :visible, values: [:visible, :hidden, :removed])

    # "Legacy" attributes (when media versions were just single files)
    field(:file_location, :string)
    field(:file_size, :integer)
    field(:mime_type, :string)
    field(:client_name, :string)
    field(:duration_seconds, :integer)

    # Virtual field for when creating new media versions (used by Updates)
    field(:explanation, :string, virtual: true)

    belongs_to(:media, Media)

    timestamps()
  end

  @doc false
  def changeset(media_version, attrs) do
    media_version
    |> cast(attrs, [
      :upload_type,
      :status,
      :source_url,
      :media_id,
      :visibility,
      :scoped_id,
      :explanation
    ])
    |> cast_embed(:artifacts)
    |> validate_required([
      :status,
      :upload_type,
      :media_id
    ])
    |> validate_length(:explanation,
      max: 2500,
      message: "Explanations cannot exceed 2500 characters."
    )
    |> unique_constraint([:media_id, :scoped_id], name: "media_versions_scoped_id_index")
  end
end
