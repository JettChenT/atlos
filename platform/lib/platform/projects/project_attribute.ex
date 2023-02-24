defmodule Platform.Projects.ProjectAttribute do
  use Ecto.Schema
  import Ecto.Changeset

  alias Platform.Material.Attribute

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field(:name, :string)
    field(:description, :string, default: "")
    field(:type, Ecto.Enum, values: [:select, :text, :date, :multi_select])
    field(:options, {:array, :string}, default: [])

    # JSON array of options
    field(:options_json, :string, virtual: true)
  end

  def compatible_types(current_type) do
    case current_type do
      :select -> [:select, :multi_select]
      :multi_select -> [:multi_select]
      :text -> [:text]
      :date -> [:date]
      nil -> [:select, :multi_select, :text, :date]
      other -> [other]
    end
  end

  def changeset(%__MODULE__{} = attribute, attrs \\ %{}) do
    options =
      Map.get(attrs, "options_json", Jason.encode!(attribute.options))
      |> then(&if &1 == "", do: Jason.encode!(attribute.options), else: &1)

    attribute
    |> cast(attrs, [:name, :type, :options_json, :id, :description])
    |> put_change(:options_json, options)
    |> cast(
      %{options: Jason.decode!(options)},
      [:options]
    )
    |> validate_required([:name, :type])
    |> validate_length(:name, min: 1, max: 40)
    |> validate_length(:description, min: 0, max: 240)
    |> validate_inclusion(:type, [:select, :text, :date, :multi_select])
    |> validate_change(:type, fn :type, type ->
      if type != attribute.type and not Enum.member?(compatible_types(attribute.type), type) do
        [type: "This is an invalid type for this attribute."]
      else
        []
      end
    end)
    |> validate_length(:options, min: 1, max: 256)
    |> then(fn changeset ->
      if Enum.member?([:select, :multi_select], get_field(changeset, :type)) do
        changeset
        |> validate_required([:options])
        |> validate_change(:options, fn :options, options ->
          if Enum.any?(options, fn option -> String.length(option) > 50 end) do
            [options: "An option cannot be longer than 50 characters"]
          else
            []
          end
        end)
        |> validate_change(:options, fn :options, options ->
          if Enum.count(options) > 256 do
            [options: "You may have at most 256 options."]
          else
            []
          end
        end)
        |> validate_change(:options, fn :options, options ->
          if Enum.count(options) != Enum.count(Enum.uniq(options)) do
            [options: "You may not have duplicate options."]
          else
            []
          end
        end)
      else
        changeset
      end
    end)
  end

  @doc """
  Convert the given ProjectAttribute into an attribute.
  """
  def to_attribute(%__MODULE__{} = attribute) do
    %Attribute{
      schema_field: :project_attributes,
      name: attribute.id,
      label: attribute.name,
      type: attribute.type,
      options: attribute.options,
      description: attribute.description,
      pane: :attributes,
      required: false
    }
  end

  def default_attributes() do
    [
      %__MODULE__{
        name: "Reported Near",
        type: :text,
        description: "Where the incident was reported to be near."
      },
      %__MODULE__{
        name: "Incident Type",
        type: :multi_select,
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
        ]
      },
      %__MODULE__{
        name: "Impact",
        type: :multi_select,
        description: "What is damaged, harmed, or lost in this incident?",
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
        ]
      },
      %__MODULE__{
        name: "Equipment",
        type: :multi_select,
        description:
          "What equipment — weapon, military infrastructure, etc. — is used in the incident?",
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
        ]
      }
    ]
  end

  def does_project_have_default_attributes?(%Platform.Projects.Project{} = project) do
    project.attributes
    |> Enum.all?(fn attribute ->
      with default <- Enum.find(default_attributes(), &(&1.name == attribute.name)),
           true <- default != nil,
           true <- default.type == attribute.type,
           true <- default.options == attribute.options,
           true <- default.description == attribute.description do
        true
      else
        _ -> false
      end
    end)
  end
end
