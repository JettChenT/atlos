defmodule Platform.Material.Attribute do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias Platform.Material.Media
  alias Platform.Accounts.User
  alias Platform.Accounts
  alias Platform.Material

  use Memoize

  defstruct [
    :schema_field,
    :type,
    :label,
    :options,
    :max_length,
    :min_length,
    :pane,
    # Allows :text to be input as :short_text or :textarea (default)
    :input_type,
    :required,
    :custom_validation,
    :name,
    :description,
    # boolean for deprecated attributes
    :deprecated,
    :add_none,
    :required_roles,
    :explanation_required,
    # for selects and multiple selects -- the values which require the user to have special privileges
    :privileged_values,
    # for selects and multiple selects
    :option_descriptions,
    # allows users to define their own options in a multi-select
    :allow_user_defined_options,
    # allows the attribute to be embedded on another attribute's edit pane (i.e., combine attributes)
    :parent
  ]

  defp renamed_attributes() do
    %{
      recorded_by: :camera_system,
      flag: :status,
      date_recorded: :date
    }
  end

  def attributes() do
    [
      %Attribute{
        schema_field: :attr_status,
        type: :select,
        options: [
          "Unclaimed",
          "In Progress",
          "Help Needed",
          "Ready for Review",
          "Completed",
          "Cancelled"
        ],
        label: "Status",
        pane: :metadata,
        required: true,
        name: :status,
        description: "Use the status to help coordinate and track work on Atlos.",
        privileged_values: ["Completed", "Cancelled"],
        option_descriptions: %{
          "Unclaimed" => "Not actively being worked on",
          "In Progress" => "Actively being worked on",
          "Help Needed" => "Stuck, or second opinion needed",
          "Ready for Review" => "Ready for a moderator's verification",
          "Completed" => "Investigation complete",
          "Cancelled" => "Will not be completed (out of scope, etc.)"
        }
      },
      %Attribute{
        schema_field: :attr_description,
        type: :text,
        max_length: 240,
        min_length: 8,
        label: "Description",
        pane: :not_shown,
        required: true,
        name: :description
      },
      %Attribute{
        schema_field: :attr_date,
        type: :date,
        label: "Date",
        pane: :attributes,
        required: false,
        name: :date,
        description: "On what date did the incident take place?"
      },
      %Attribute{
        schema_field: :attr_general_location,
        type: :text,
        input_type: :short_text,
        max_length: 240,
        min_length: 2,
        label: "Reported Near",
        pane: :attributes,
        required: false,
        name: :general_location
      },
      %Attribute{
        schema_field: :attr_tags,
        type: :multi_select,
        label: "Tags",
        pane: :metadata,
        required: false,
        name: :tags,
        required_roles: [:admin, :trusted],
        allow_user_defined_options: true,
        description: "Use tags to help organize incidents on Atlos."
      },
      %Attribute{
        schema_field: :attr_type,
        type: :multi_select,
        # Set in ATTRIBUTE_OPTIONS environment variable to override
        options: [
          "Military Activity",
          "Military Activity/Movement",
          "Military Activity/Equipment",
          "Military Activity/Equipment/Lost",
          "Military Activity/Execution",
          "Military Activity/Combat",
          "Military Activity/Encampment",
          "Military Activity/Strike",
          "Military Activity/Explosion",
          "Military Activity/Detention",
          "Military Activity/Mass Grave",
          "Military Activity/Demolition",
          "Civilian Activity",
          "Civilian Activity/Protest or March",
          "Civilian Activity/Riot",
          "Civilian Activity/Violence",
          "Policing",
          "Policing/Use of Force",
          "Policing/Detention",
          "Weather",
          "Weather/Flooding",
          "Weather/Hurricane",
          "Weather/Fire",
          "Other"
        ],
        label: "Incident Type",
        description: "What type of incident is this? Select all that apply.",
        pane: :attributes,
        required: true,
        name: :type
      },
      %Attribute{
        schema_field: :attr_impact,
        type: :multi_select,
        # Set in ATTRIBUTE_OPTIONS environment variable to override
        options: [
          "Structure",
          "Structure/Residential",
          "Structure/Residential/House",
          "Structure/Residential/Apartment",
          "Structure/Healthcare",
          "Structure/Humanitarian",
          "Structure/Food Infrastructure",
          "Structure/School or Childcare",
          "Structure/Park or Playground",
          "Structure/Cultural",
          "Structure/Religious",
          "Structure/Industrial",
          "Structure/Administrative",
          "Structure/Commercial",
          "Structure/Roads, Highways, or Transport",
          "Structure/Transit Station",
          "Structure/Airport",
          "Structure/Military",
          "Land Vehicle",
          "Land Vehicle/Car",
          "Land Vehicle/Truck",
          "Land Vehicle/Armored",
          "Land Vehicle/Train",
          "Land Vehicle/Bus",
          "Aircraft",
          "Aircraft/Fighter",
          "Aircraft/Bomber",
          "Aircraft/Helicopter",
          "Aircraft/Drone",
          "Sea Vehicle",
          "Sea Vehicle/Boat",
          "Sea Vehicle/Warship",
          "Sea Vehicle/Aircraft Carrier",
          "Injury",
          "Injury/Civilian",
          "Injury/Combatant",
          "Death",
          "Death/Civilian",
          "Death/Combatant"
        ],
        label: "Impact",
        description: "What is damaged, harmed, or lost in this incident?",
        pane: :attributes,
        required: false,
        name: :impact,
        add_none: "None"
      },
      %Attribute{
        schema_field: :attr_equipment,
        type: :multi_select,
        # Set in ATTRIBUTE_OPTIONS environment variable to override
        options: [
          "Small Arm",
          "Munition",
          "Munition/Cluster",
          "Munition/Chemical",
          "Munition/Thermobaric",
          "Munition/Incendiary",
          "Non-Lethal Weapon",
          "Non-Lethal Weapon/Tear Gas",
          "Non-Lethal Weapon/Rubber Bullet",
          "Land Mine",
          "Launch System",
          "Launch System/Artillery",
          "Launch System/Self-Propelled",
          "Launch System/Multiple Launch Rocket System",
          "Land Vehicle",
          "Land Vehicle/Car",
          "Land Vehicle/Armored",
          "Aircraft",
          "Aircraft/Fighter",
          "Aircraft/Bomber",
          "Aircraft/Helicopter",
          "Aircraft/Drone",
          "Sea Vehicle",
          "Sea Vehicle/Small Boat",
          "Sea Vehicle/Ship",
          "Sea Vehicle/Aircraft Carrier"
        ],
        label: "Equipment Used",
        description:
          "What equipment — weapon, military infrastructure, etc. — is used in the incident?",
        pane: :attributes,
        required: false,
        name: :equipment
      },
      %Attribute{
        schema_field: :attr_time_of_day,
        type: :select,
        options: [],
        label: "Day/Night (Deprecated)",
        pane: :attributes,
        required: false,
        deprecated: true,
        name: :time_of_day
      },
      %Attribute{
        schema_field: :attr_geolocation,
        description:
          "For incidents that span multiple locations (e.g., movement down a street or a fire), choose a representative verifiable location. All geolocations must be confirmable visually.",
        type: :location,
        label: "Geolocation",
        pane: :attributes,
        required: false,
        name: :geolocation
      },
      %Attribute{
        schema_field: :attr_geolocation_resolution,
        type: :select,
        label: "Precision",
        pane: :not_shown,
        required: false,
        name: :geolocation_resolution,
        parent: :geolocation,
        options: [
          "Exact",
          "Vicinity",
          "Locality"
        ],
        option_descriptions: %{
          "Exact" => "Maximum precision (± 10m)",
          "Vicinity" => "Same complex, block, field, etc. (± 100m)",
          "Locality" => "Same neighborhood, village, etc. (± 1km)"
        }
      },
      %Attribute{
        schema_field: :attr_environment,
        type: :select,
        options: [],
        label: "Environment (Deprecated)",
        pane: :attributes,
        required: false,
        name: :environment,
        deprecated: true,
        description:
          "What is primarily in view? Note that this does not refer to where the media was captured."
      },
      %Attribute{
        schema_field: :attr_weather,
        type: :multi_select,
        options: [],
        label: "Weather (Deprecated)",
        pane: :attributes,
        required: false,
        name: :weather,
        deprecated: true,
        add_none: "Indeterminable"
      },
      %Attribute{
        schema_field: :attr_camera_system,
        type: :multi_select,
        options: [],
        label: "Camera System (Deprecated)",
        pane: :attributes,
        required: false,
        name: :camera_system,
        deprecated: true,
        description:
          "What kinds of camera systems does the media use? If there are multiple pieces of media, select all that apply."
      },
      %Attribute{
        schema_field: :attr_more_info,
        type: :text,
        max_length: 3000,
        label: "More Info",
        pane: :attributes,
        required: false,
        name: :more_info,
        description: "For example, information noted by the source."
      },
      %Attribute{
        schema_field: :attr_civilian_impact,
        type: :multi_select,
        options: [],
        label: "Civilian Impact (Deprecated)",
        pane: :attributes,
        required: false,
        name: :civilian_impact,
        deprecated: true,
        add_none: "None"
      },
      %Attribute{
        schema_field: :attr_event,
        type: :multi_select,
        options: [],
        label: "Event (Deprecated)",
        pane: :attributes,
        required: false,
        name: :event,
        description: "What events are visible in the incident's media?",
        deprecated: true,
        add_none: "None"
      },
      %Attribute{
        schema_field: :attr_casualty,
        type: :multi_select,
        options: [],
        label: "Casualty (Deprecated)",
        pane: :attributes,
        required: false,
        name: :casualty,
        deprecated: true,
        add_none: "None"
      },
      %Attribute{
        schema_field: :attr_military_infrastructure,
        type: :multi_select,
        options: [],
        label: "Military Infrastructure (Deprecated)",
        pane: :attributes,
        required: false,
        name: :military_infrastructure,
        description: "What military infrastructure is visible in the media?",
        deprecated: true,
        add_none: "None"
      },
      %Attribute{
        schema_field: :attr_weapon,
        type: :multi_select,
        options: [],
        label: "Weapon (Deprecated)",
        pane: :attributes,
        required: false,
        name: :weapon,
        description: "What weapons are visible in the incident's media?",
        deprecated: true,
        add_none: "None"
      },
      %Attribute{
        schema_field: :attr_time_recorded,
        type: :time,
        label: "Time Recorded (Deprecated)",
        pane: :attributes,
        required: false,
        name: :time_recorded,
        deprecated: true,
        description: "What time of day was the incident? Use the local timezone, if possible."
      },
      %Attribute{
        schema_field: :attr_restrictions,
        type: :multi_select,
        label: "Restrictions",
        pane: :metadata,
        required: false,
        name: :restrictions,
        # NOTE: Editing these values also requires editing the perm checks in `media.ex`
        options: ["Frozen", "Hidden"],
        required_roles: [:admin, :trusted]
      },
      %Attribute{
        schema_field: :attr_sensitive,
        type: :multi_select,
        options: [
          "Personal Information Visible",
          "Graphic Violence",
          "Deleted by Source",
          "Deceptive or Misleading"
        ],
        option_descriptions: %{
          "Personal Information Visible" => "Could identify individuals or their location",
          "Graphic Violence" => "Media contains violence or other graphic imagery",
          "Deleted by Source" => "The media has been deleted from its original location",
          "Deceptive or Misleading" =>
            "The media is a hoax, misinformation, or otherwise deceptive",
          "Not Sensitive" => "The media is not sensitive"
        },
        label: "Sensitivity",
        min_length: 1,
        pane: :metadata,
        required: true,
        name: :sensitive,
        add_none: "Not Sensitive",
        description:
          "Is this incident sensitive? This information helps us keep our community safe."
      }
    ]
  end

  @doc """
  Get all the active, non-deprecated attributes.
  """
  def active_attributes() do
    attributes() |> Enum.filter(&(&1.deprecated != true))
  end

  @doc """
  Get the names of the attributes that are available for the given media. Both nil and the empty list count as unset.

  If the :pane option is given, only attributes in that pane will be returned.
  """
  def set_for_media(media, opts \\ []) do
    pane = Keyword.get(opts, :pane)

    Enum.filter(attributes(), fn attr ->
      val = Map.get(media, attr.schema_field)
      val != nil && val != [] && (pane == nil || attr.pane == pane) && attr.deprecated != true
    end)
  end

  @doc """
  Get the names of the attributes that are not available for the given media. Both nil and the empty list count as unset.

  If the :pane option is given, only attributes in that pane will be returned.
  """
  def unset_for_media(media, opts \\ []) do
    pane = Keyword.get(opts, :pane)
    set = set_for_media(media)

    attributes()
    |> Enum.filter(&(!Enum.member?(set, &1)))
    |> Enum.filter(&(&1.deprecated != true))
    |> Enum.filter(&(pane == nil || &1.pane == pane))
  end

  @doc """
  Get the names of all attributes, optionally including deprecated ones.

  If the :include_renamed_attributes option is true, renamed attributes will be included.
  If the :include_deprecated_attributes option is true, deprecated attributes will be included.
  """
  def attribute_names(opts \\ []) do
    include_deprecated_attributes = Keyword.get(opts, :include_deprecated_attributes, false)
    include_renamed_attributes = Keyword.get(opts, :include_renamed_attributes, false)

    (attributes()
     |> Enum.filter(&(&1.deprecated != true or include_deprecated_attributes))
     |> Enum.map(& &1.name)) ++
      if include_renamed_attributes, do: Map.keys(renamed_attributes()), else: []
  end

  @doc """
  Get an attribute by its name. Will check whether the attribute has been renamed.
  """
  def get_attribute(name) do
    # Some attributes have been renamed; this allows us to keep updates
    # that reference the old name working.
    real_name =
      case renamed_attributes() do
        %{^name => new_name} -> new_name
        _ -> name
      end
      |> to_string()

    Enum.find(attributes(), &(&1.name |> to_string() == real_name))
  end

  @doc """
  Get an attribute by its schema field name.
  """
  def get_attribute_by_schema_field(name) do
    name = name |> to_string()
    Enum.find(attributes(), &(&1.schema_field |> to_string() == name))
  end

  @doc """
  Create a changeset for the media from the given attribute.

  Options:
    * :user - the user making the change (default: nil)
    * :verify_change_exists - whether to verify that the change exists (default: true)
    * :changeset - an existing changeset to add to (default: nil)
  """
  def changeset(
        %Media{} = media,
        %Attribute{} = attribute,
        attrs \\ %{},
        opts \\ []
      ) do
    user = Keyword.get(opts, :user)
    verify_change_exists = Keyword.get(opts, :verify_change_exists, true)
    changeset = Keyword.get(opts, :changeset)

    (changeset || media)
    |> cast(%{}, [])
    |> populate_virtual_data(attribute)
    |> cast_attribute(attribute, attrs)
    |> validate_attribute(attribute, user: user)
    |> cast_and_validate_virtual_explanation(attrs, attribute)
    |> update_from_virtual_data(attribute)
    |> verify_user_can_edit(attribute, user, media)
    |> then(fn c ->
      if verify_change_exists, do: verify_change_exists(c, [attribute]), else: c
    end)
  end

  @doc """
  Create a changeset for the media from the given attributes.

  Options:
    * :user - the user making the change (default: nil)
    * :verify_change_exists - whether to verify that the change exists (default: true)
    * :changeset - an existing changeset to add to (default: nil)
  """
  def combined_changeset(
        %Media{} = media,
        attributes,
        attrs \\ %{},
        opts \\ []
      ) do
    user = Keyword.get(opts, :user)
    verify_change_exists = Keyword.get(opts, :verify_change_exists, true)
    changeset = Keyword.get(opts, :changeset)

    Enum.reduce(attributes, changeset || media, fn elem, acc ->
      changeset(media, elem, attrs, user: user, verify_change_exists: false, changeset: acc)
    end)
    |> then(fn c ->
      if verify_change_exists, do: verify_change_exists(c, attributes), else: c
    end)
  end

  @doc """
  Checks whether the given user can edit the given attribute.
  """
  def verify_user_can_edit(changeset, attribute, user, media) do
    if is_nil(user) || can_user_edit(attribute, user, media) do
      changeset
    else
      changeset
      |> Ecto.Changeset.add_error(
        attribute.schema_field,
        "You do not have permission to edit this attribute."
      )
    end
  end

  defp populate_virtual_data(changeset, %Attribute{} = attribute) do
    # Populates the virtual data for the given attribute. Specifically, it:
    # * Sets the location field to a string representation of the location.

    case attribute.type do
      :location ->
        with %Geo.Point{coordinates: {lon, lat}} <- get_field(changeset, attribute.schema_field) do
          changeset |> put_change(:location, to_string(lat) <> ", " <> to_string(lon))
        else
          _ -> changeset
        end

      _ ->
        changeset
    end
  end

  defp update_from_virtual_data(changeset, %Attribute{} = attribute) do
    # Updates the data in the changeset for the given attribute from the virtual data. Specifically, it:
    # * Sets the location field by parsing the string representation of the location.

    case attribute.type do
      :location ->
        error_msg =
          "Unable to parse this location; please enter a latitude-longitude pair separated by commas."

        coords =
          (Map.get(changeset.changes, :location, changeset.data.location) || "")
          |> String.trim()
          |> String.split(",")

        case coords do
          [""] ->
            changeset
            |> put_change(attribute.schema_field, nil)

          [lat_string, lon_string] ->
            with {lat, ""} <- Float.parse(lat_string |> String.trim()),
                 {lon, ""} <- Float.parse(lon_string |> String.trim()) do
              changeset
              |> put_change(attribute.schema_field, %Geo.Point{
                coordinates: {lon, lat},
                srid: 4326
              })
            else
              _ ->
                changeset
                |> add_error(
                  attribute.schema_field,
                  error_msg
                )
            end

          _ ->
            changeset
            |> add_error(
              attribute.schema_field,
              error_msg
            )
        end

      _ ->
        changeset
    end
  end

  defp cast_attribute(media_or_changeset, %Attribute{} = attribute, attrs) do
    # Casts the given attribute in the Media changeset from the given attrs.

    if attribute.deprecated == true do
      raise "cannot cast deprecated attribute"
    end

    media_or_changeset
    |> cast(attrs, [:explanation], message: "Unable to parse explanation.")
    |> then(fn changeset ->
      case attribute.type do
        # Explanation is a virtual field! We cast here so we can validate.
        # TODO: Is there an idiomatic way to clean this up?
        :location ->
          changeset
          |> cast(attrs, [:location])

        _ ->
          changeset
          |> cast(attrs, [attribute.schema_field])
      end
    end)
    |> then(fn changeset ->
      changeset
      |> Map.put(
        :errors,
        changeset.errors
        |> Enum.map(fn {attr, {error_message, metadata}} ->
          cond do
            attribute.type == :time and attr == attribute.schema_field ->
              {attr, {"Time must include an hour and minute.", metadata}}

            attribute.type == :date and attr == attribute.schema_field ->
              {attr,
               {"Verify the date is valid. Date must include a year, month, and day.", metadata}}

            true ->
              {attr, {error_message, metadata}}
          end
        end)
      )
    end)
  end

  defmemo get_custom_attribute_options(name) do
    # TODO: Remove this -- it's a temporary hack to allow us to add options to attributes without
    # having to deploy code.
    extra = Jason.decode!(System.get_env("ATTRIBUTE_OPTIONS", "{}"))

    Map.get(extra, name |> to_string(), [])
  end

  @doc """
  Get the options for the provided attribute. If the attribute has custom options, those are provided.
  If the attribute allows user-defined options, those are provided. If the attribute has a "none" option,
  that is provided. If the attribute is a multi-select, the current values are included (provided `current_val`
  is given).
  """
  def options(%Attribute{} = attribute, current_val \\ nil) do
    options =
      case get_custom_attribute_options(attribute.name) do
        [] -> attribute.options || []
        values -> values
      end

    options =
      if Attribute.allow_user_defined_options(attribute) and attribute.type == :multi_select do
        options ++ Material.get_values_of_attribute_cached(attribute)
      else
        options
      end

    options =
      if attribute.add_none do
        [attribute.add_none] ++ options
      else
        options
      end

    if is_list(current_val) do
      options ++ current_val
    else
      options
    end
  end

  @doc """
  Validates the given attribute in the given changeset.

  Options:
    * `:user` - the user performing the action.
    * `:required` - whether the attribute is required. Defaults to true.
  """
  def validate_attribute(changeset, %Attribute{} = attribute, opts \\ []) do
    user = Keyword.get(opts, :user, nil)
    required = Keyword.get(opts, :required, true)

    validations =
      case attribute.type do
        :multi_select ->
          if Attribute.allow_user_defined_options(attribute) == true do
            # If `allow_user_defined_options` is unset or false, verify that the
            # values are a subset of the options.
            changeset
          else
            changeset
            |> validate_subset(attribute.schema_field, options(attribute),
              message:
                "Includes an invalid value. Valid values are: " <>
                  Enum.join(options(attribute), ", ")
            )
          end
          |> validate_length(attribute.schema_field,
            min: attribute.min_length,
            max: attribute.max_length
          )
          |> validate_change(attribute.schema_field, fn _, vals ->
            if attribute.add_none && Enum.member?(vals, attribute.add_none) && length(vals) > 1 do
              [
                {attribute.schema_field,
                 "If '#{attribute.add_none}' is selected, no other options are allowed."}
              ]
            else
              []
            end
          end)
          |> validate_privileged_values(attribute, user)

        :select ->
          changeset
          |> validate_inclusion(attribute.schema_field, options(attribute),
            message:
              "Includes an invalid value. Valid values are: " <>
                Enum.join(options(attribute), ", ")
          )
          |> validate_privileged_values(attribute, user)

        :text ->
          changeset
          |> validate_length(attribute.schema_field,
            min: attribute.min_length,
            max: attribute.max_length
          )

        _ ->
          changeset
      end

    custom =
      if attribute.custom_validation != nil do
        validations |> validate_change(attribute.schema_field, attribute.custom_validation)
      else
        validations
      end

    if attribute.required and required do
      custom |> validate_required([attribute.schema_field])
    else
      custom
    end
  end

  defp cast_and_validate_virtual_explanation(changeset, params, attribute) do
    # Cast and validate the `explanation` field, which is virtual and not part of the schema.
    # Instead, it's passed to the `update` model. Some attributes require an explanation,
    # and some don't -- that is validated by this function.

    change =
      changeset
      |> cast(params, [:explanation])
      |> validate_length(:explanation,
        max: 2500,
        message: "Explanations cannot exceed 2500 characters."
      )

    if attribute.explanation_required do
      change
      |> validate_required(:explanation,
        message: "An explanation is required to update this attribute."
      )
      |> validate_length(:explanation,
        min: 10,
        message: "An explanation of at least 10 characters is required to update this attribute."
      )
    else
      change
    end
  end

  defp validate_privileged_values(changeset, %Attribute{} = attribute, %User{} = user)
       when is_list(attribute.privileged_values) do
    # Some attributes have values that can only be set by privileged users. This function
    # validates that the values are not set by non-privileged users.

    if Accounts.is_privileged(user) do
      # Changes by a privileged user can do anything
      changeset
    else
      values = attribute.privileged_values

      case get_field(changeset, attribute.schema_field) do
        v when is_list(v) ->
          requires_privilege =
            MapSet.intersection(Enum.into(v, MapSet.new()), Enum.into(values, MapSet.new()))

          if not Enum.empty?(requires_privilege) do
            changeset
            |> add_error(
              attribute.schema_field,
              "Only moderators can set the following values: " <>
                Enum.join(requires_privilege, ", ")
            )
          else
            changeset
          end

        v ->
          if Enum.member?(values, v) do
            changeset
            |> add_error(
              attribute.schema_field,
              "Only moderators can set the value to '" <> v <> "'"
            )
          else
            changeset
          end
      end
    end
  end

  defp validate_privileged_values(changeset, _attribute, _user) do
    # When attribute and user aren't provided, or there are no privileged values,
    # then there is nothing to validate.

    changeset
  end

  defp verify_change_exists(changeset, attributes) do
    # Verify that at least one of the given attributes has changed. This is used
    # to ensure that users don't post updates that don't actually change anything.

    if not Enum.any?(attributes, &Map.has_key?(changeset.changes, &1.schema_field)) do
      changeset
      |> add_error(hd(attributes).schema_field, "A change is required to post an update.")
    else
      changeset
    end
  end

  @doc """
  Can the given user edit the given attribute for the given media? This also checks
  whether they are allowed to edit the given media.
  """
  def can_user_edit(%Attribute{} = attribute, %User{} = user, %Media{} = media) do
    user_roles = user.roles || []

    with true <- Media.can_user_edit(media, user) do
      case attribute.required_roles || [] do
        [] -> true
        [hd | tail] -> Enum.any?([hd] ++ tail, &Enum.member?(user_roles, &1))
      end
    else
      _ -> false
    end
  end

  @doc """
  Get the color (in "a17t" terms) for the given attribute value.
  """
  def attr_color(name, value) do
    case name do
      :sensitive ->
        case value do
          ["Not Sensitive"] -> "~neutral"
          _ -> "~critical"
        end

      :status ->
        case value do
          "Unclaimed" -> "~positive"
          "In Progress" -> "~purple"
          "Cancelled" -> "~neutral"
          "Ready for Review" -> "~cyan"
          "Completed" -> "~urge"
          "Needs Upload" -> "~neutral"
          _ -> "~warning"
        end

      _ ->
        "~neutral"
    end
  end

  @doc """
  Checks whether the attribute allows user-defined options (i.e., custom new options).
  """
  def allow_user_defined_options(%Attribute{allow_user_defined_options: true}) do
    true
  end

  def allow_user_defined_options(%Attribute{}) do
    false
  end

  @doc """
  Checks whether the attribute requires special privileges to edit.
  """
  def requires_privileges_to_edit(%Attribute{} = attr) do
    is_list(attr.required_roles) and not Enum.empty?(attr.required_roles)
  end

  @doc """
  Get the child attributes of the given parent attribute. Children are used to combine multiple
  distinct attributes into a single editing experience (e.g., geolocation and geolocation accuracy).
  """
  def get_children(parent_name) do
    attributes() |> Enum.filter(&(&1.parent == parent_name))
  end
end
