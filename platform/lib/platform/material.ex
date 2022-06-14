defmodule Platform.Material do
  @moduledoc """
  The Material context.
  """

  import Ecto.Query, warn: false
  alias Platform.Repo
  require Logger

  alias Phoenix.PubSub

  alias Platform.Material.Media
  alias Platform.Material.Attribute
  alias Platform.Material.MediaVersion
  alias Platform.Material.MediaSubscription
  alias Platform.Utils
  alias Platform.Updates
  alias Platform.Accounts.User
  alias Platform.Uploads
  alias Platform.Auditor
  alias Platform.Accounts

  defp hydrate_media_query(query) do
    query
    |> preload_media_versions()
    |> preload_media_updates()
  end

  @doc """
  Returns the list of media. Will preload the versions and updates.

  ## Examples

      iex> list_media()
      [%Media{}, ...]

  """
  def list_media do
    Media
    |> hydrate_media_query()
    |> order_by(desc: :updated_at)
    |> Repo.all()
  end

  defp _query_media(query) do
    # Helper function used to abstract behavior of the `query_media` functions.
    query
    |> hydrate_media_query()
    |> order_by(desc: :updated_at)
  end

  @doc """
  Query the list of media. Will preload the versions and updates.
  """
  def query_media(query \\ Media) do
    _query_media(query)
    |> Repo.all()
  end

  @doc """
  Query the list of media, paginated. Will preload the versions and updates. Behavior otherwise the same as query_media/1.
  """
  def query_media_paginated(query \\ Media, opts \\ []) do
    applied_options = Keyword.merge([cursor_fields: [{:updated_at, :desc}], limit: 30], opts)

    _query_media(query)
    |> Repo.paginate(applied_options)
  end

  @doc """
  Returns the list of media subscribed to by the given user.
  """
  def list_subscribed_media(%User{} = user) do
    user
    |> Ecto.assoc(:subscribed_media)
    |> order_by(desc: :updated_at)
    |> hydrate_media_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of geolocated media.
  """
  def list_geolocated_media() do
    Media
    |> where([i], not is_nil(i.attr_geolocation))
    |> hydrate_media_query()
    |> Repo.all()
  end

  defp preload_media_versions(query) do
    query |> preload([:versions])
  end

  defp preload_media_updates(query) do
    # TODO: should this be pulled into the Updates context somehow?
    query |> preload(updates: [:user, :media, :media_version])
  end

  @doc """
  Gets a single media.

  Raises `Ecto.NoResultsError` if the Media does not exist.

  ## Examples

      iex> get_media!(123)
      %Media{}

      iex> get_media!(456)
      ** (Ecto.NoResultsError)

  """
  def get_media!(id), do: Repo.get!(Media, id)

  @doc """
  Creates a media.

  ## Examples

      iex> create_media(%{field: value})
      {:ok, %Media{}}

      iex> create_media(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_media(attrs \\ %{}) do
    %Media{}
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  def create_media_audited(%User{} = user, attrs \\ %{}) do
    changeset =
      %Media{}
      |> Media.changeset(attrs)

    cond do
      !changeset.valid? ->
        {:error, changeset}

      true ->
        Repo.transaction(fn ->
          {:ok, media} =
            %Media{}
            |> Media.changeset(attrs)
            |> Repo.insert()

          {:ok, _} =
            Updates.change_from_media_creation(media, user)
            |> Updates.create_update_from_changeset()

          media
        end)
    end
  end

  def get_full_media_by_slug(slug) do
    Media |> preload_media_versions() |> preload_media_updates() |> Repo.get_by(slug: slug)
  end

  @doc """
  Updates a media.

  ## Examples

      iex> update_media(media, %{field: new_value})
      {:ok, %Media{}}

      iex> update_media(media, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a media.

  ## Examples

      iex> delete_media(media)
      {:ok, %Media{}}

      iex> delete_media(media)
      {:error, %Ecto.Changeset{}}

  """
  def delete_media(%Media{} = media) do
    Repo.delete(media)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking media changes.

  ## Examples

      iex> change_media(media)
      %Ecto.Changeset{data: %Media{}}

  """
  def change_media(%Media{} = media, attrs \\ %{}) do
    Media.changeset(media, attrs)
  end

  @doc """
  Returns the list of media_versions.

  ## Examples

      iex> list_media_versions()
      [%MediaVersion{}, ...]

  """
  def list_media_versions do
    Repo.all(MediaVersion)
  end

  @doc """
  Gets a single media_version.

  Raises `Ecto.NoResultsError` if the Media version does not exist.

  ## Examples

      iex> get_media_version!(123)
      %MediaVersion{}

      iex> get_media_version!(456)
      ** (Ecto.NoResultsError)

  """
  def get_media_version!(id), do: Repo.get!(MediaVersion, id)

  def pubsub_topic_for_media(id) do
    "media_updates:#{id}"
  end

  @doc """
  Broadcast that the media was updated on its PubSub channel.
  """
  def broadcast_media_updated(media_id) do
    Task.start(fn ->
      # Add a delay to let everything settle. There's probably a way to do this more robustly.
      :timer.sleep(500)
      PubSub.broadcast(Platform.PubSub, pubsub_topic_for_media(media_id), {:media_updated})
    end)
  end

  def get_media_versions_by_source_url(url) do
    Repo.all(
      from v in MediaVersion,
        where: v.source_url == ^url,
        preload: [media: [[updates: :user], :versions]]
    )
    |> Enum.sort_by(& &1.media.id)
    |> Enum.dedup_by(& &1.media.id)
  end

  def create_media_version(%Media{} = media, attrs \\ %{}) do
    %MediaVersion{}
    |> MediaVersion.changeset(attrs |> Map.put("media_id", media.id) |> Utils.make_keys_strings())
    |> Repo.insert()
  end

  def create_media_version_audited(
        %Media{} = media,
        %User{} = user,
        attrs \\ %{}
      ) do
    if Media.can_user_edit(media, user) do
      Repo.transaction(fn ->
        with {:ok, version} <- create_media_version(media, attrs),
             update_changeset <- Updates.change_from_media_version_upload(media, user, version),
             {:ok, _} <- Updates.create_update_from_changeset(update_changeset) do
          version
        else
          _ -> {:error, change_media_version(%MediaVersion{}, attrs)}
        end
      end)
    else
      # Note: Updates.create_update_from_changeset will also catch the permissions error, but it's good to have multiple layers.
      {:error,
       change_media_version(%MediaVersion{}, attrs)
       |> Ecto.Changeset.add_error(:source_url, "This media has been locked.")}
    end
  end

  @doc """
  Updates a media_version.

  ## Examples

      iex> update_media_version(media_version, %{field: new_value})
      {:ok, %MediaVersion{}}

      iex> update_media_version(media_version, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_media_version(%MediaVersion{} = media_version, attrs) do
    media_version
    |> MediaVersion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a media_version.

  ## Examples

      iex> delete_media_version(media_version)
      {:ok, %MediaVersion{}}

      iex> delete_media_version(media_version)
      {:error, %Ecto.Changeset{}}

  """
  def delete_media_version(%MediaVersion{} = media_version) do
    Repo.delete(media_version)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking media_version changes.

  ## Examples

      iex> change_media_version(media_version)
      %Ecto.Changeset{data: %MediaVersion{}}

  """
  def change_media_version(%MediaVersion{} = media_version, attrs \\ %{}) do
    MediaVersion.changeset(media_version, attrs)
  end

  @doc """
  Performs an archive of the given media version. Status must be pending.
  """
  def archive_media_version(%MediaVersion{status: :pending, media_id: media_id} = version) do
    # Get the associated media
    media = get_media!(media_id)

    try do
      # Setup tempfiles for media download
      Temp.track!()
      temp_dir = Temp.mkdir!()

      # Download the media
      {_, 0} =
        System.cmd(
          "yt-dlp",
          [
            version.source_url,
            "-o",
            Path.join(temp_dir, "out.%(ext)s"),
            "--max-filesize",
            "500m"
          ],
          into: IO.stream()
        )

      # Figure out what we downloaded
      [file_name] = File.ls!(temp_dir)
      file_path = Path.join(temp_dir, file_name)
      mime = MIME.from_path(file_path)

      # Process + upload it
      {:ok, identifier, duration, size} = process_uploaded_media(file_path, mime, media)

      # Update the media version to reflect the change
      {:ok, new_version} =
        update_media_version(version, %{
          file_location: identifier,
          file_size: size,
          status: :complete,
          duration_seconds: duration,
          mime_type: mime
        })

      # Track event
      Auditor.log(:archive_success, %{media_id: media_id, source_url: new_version.source_url})

      Updates.change_from_comment(media, Accounts.get_auto_account(), %{
        "explanation" => "✅ Successfully archived the media at <#{version.source_url}>."
      })
      |> Updates.create_update_from_changeset()

      new_version
    rescue
      val ->
        # Some error happened! Log it and update the media version appropriately.
        Logger.error("Unable to automatically archive media!")
        Auditor.log(:archive_failed, %{error: val, version: version})

        Updates.change_from_comment(media, Accounts.get_auto_account(), %{
          "explanation" =>
            "🛑 Unable to automatically download the media from <#{version.source_url}>. Either no video is available, there are multiple possible videos, or the archival system is temporarily broken. (Note that we cannot automatically archive images.) Please consider uploading the media manually."
        })
        |> Updates.create_update_from_changeset()

        {:ok, new_version} =
          update_media_version(version, %{
            status: :error
          })

        new_version
    end
  end

  @doc """
  Preprocesses the given media and uploads it to persistent storage.

  Returns {:ok, file_path, thumbnail_path, duration}
  """
  def process_uploaded_media(path, mime, media) do
    identifier = media.slug

    media_path =
      cond do
        String.starts_with?(mime, "image/") -> Temp.path!(%{suffix: ".jpg", prefix: identifier})
        String.starts_with?(mime, "video/") -> Temp.path!(%{suffix: ".mp4", prefix: identifier})
      end

    font_path =
      System.get_env(
        "WATERMARK_FONT_PATH",
        Path.join(:code.priv_dir(:platform), "static/fonts/iosevka-bold.ttc")
      )

    IO.puts("Loading font from #{font_path}; file exists? #{File.exists?(font_path)}")

    process_command =
      FFmpex.new_command()
      |> FFmpex.add_input_file(path)
      |> FFmpex.add_output_file(media_path)
      |> FFmpex.add_file_option(
        FFmpex.Options.Video.option_vf(
          "drawtext=text='#{identifier}':x=20:y=20:fontfile=#{font_path}:fontsize=24:fontcolor=white:box=1:boxcolor=black@0.25:boxborderw=5"
        )
      )

    {:ok, _} = FFmpex.execute(process_command)

    {:ok, out_data} = FFprobe.format(media_path)

    {duration, _} = Integer.parse(out_data["duration"])
    {size, _} = Integer.parse(out_data["size"])

    # Upload to cloud storage
    {:ok, new_path} = Uploads.WatermarkedMediaVersion.store({media_path, media})
    {:ok, _original_path} = Uploads.OriginalMediaVersion.store({path, media})

    {:ok, new_path, duration, size}
  end

  def media_version_location(version, media) do
    cond do
      is_nil(version.file_location) ->
        nil

      String.starts_with?(version.file_location, "https://") ->
        version.file_location

      true ->
        Uploads.WatermarkedMediaVersion.url({version.file_location, media}, :original,
          signed: true
        )
    end
  end

  @doc """
  Changeset for the media attribute. Also checks permissions.
  """
  def change_media_attribute(
        %Media{} = media,
        %Attribute{} = attribute,
        %User{} = user,
        attrs \\ %{}
      ) do
    changeset = Attribute.changeset(media, attribute, attrs, user)

    if Attribute.can_user_edit(attribute, user, media) do
      changeset
    else
      changeset
      |> Ecto.Changeset.add_error(
        attribute.schema_field,
        "You do not have permission to edit this attribute."
      )
    end
  end

  def update_media_attribute(media, %Attribute{} = attribute, attrs, user \\ nil) do
    media
    |> Attribute.changeset(attribute, attrs, user)
    |> Repo.update()
  end

  @doc """
  Do an audited update of the given attribute. Will broadcast change via PubSub.
  """
  def update_media_attribute_audited(media, %Attribute{} = attribute, %User{} = user, attrs) do
    media_changeset = change_media_attribute(media, attribute, user, attrs)

    update_changeset =
      Updates.change_from_attribute_changeset(media, attribute, user, media_changeset, attrs)

    # Make sure both changesets are valid
    cond do
      !(media_changeset.valid? && update_changeset.valid?) ->
        {:error, media_changeset}

      true ->
        Repo.transaction(fn ->
          {:ok, _} = Updates.create_update_from_changeset(update_changeset)
          {:ok, res} = update_media_attribute(media, attribute, attrs, user)
          res
        end)
    end
  end

  def get_subscription(%Media{} = media, %User{} = user) do
    Repo.get_by(MediaSubscription, media_id: media.id, user_id: user.id)
  end

  def subscribe_user(%Media{} = media, %User{} = user) do
    MediaSubscription.changeset(%MediaSubscription{}, %{media_id: media.id, user_id: user.id})
    |> Repo.insert()
  end

  def unsubscribe_user(%Media{} = media, %User{} = user) do
    with {1, _} <-
           from(s in MediaSubscription,
             where: s.media_id == ^media.id,
             where: s.user_id == ^user.id
           )
           |> Repo.delete_all() do
      :ok
    else
      _ -> :error
    end
  end

  def total_subscribed!(%Media{} = media) do
    [count] =
      Repo.all(
        from w in MediaSubscription,
          where: w.media_id == ^media.id,
          select: count()
      )

    count
  end

  def media_thumbnail(%Media{} = media) do
    case Enum.find(
           media.versions |> Enum.sort_by(& &1.updated_at) |> Enum.reverse(),
           &(!(&1.visibility != :visible or is_nil(&1.file_location)))
         ) do
      nil ->
        nil

      val ->
        if String.starts_with?(val.file_location, "https://"),
          # This allows us to have easy demo data — just give a raw HTTPS URL
          do: val.file_location,
          else:
            Uploads.WatermarkedMediaVersion.url({val.file_location, media}, :thumb, signed: true)
    end
  end

  def contributors(%Media{} = media) do
    Enum.uniq(media.updates |> Enum.filter(&(not &1.hidden)) |> Enum.map(& &1.user))
  end
end
