defmodule PlatformWeb.MediaLive.PaginatedMediaList do
  use PlatformWeb, :live_component
  alias Platform.Material

  def update(%{query_params: params, current_user: _user} = assigns, socket) do
    hydrated_socket = socket |> assign(assigns)

    results = search_media(hydrated_socket, Material.MediaSearch.changeset(params))

    {:ok,
     hydrated_socket
     |> assign(:results, results)
     |> assign(:media, results.entries)
     |> assign_new(:show_subscription_button, fn -> false end)}
  end

  def handle_event("load_more", _params, socket) do
    cursor_after = socket.assigns.results.metadata.after

    results =
      search_media(socket, Material.MediaSearch.changeset(socket.assigns.query_params),
        after: cursor_after
      )

    new_socket =
      socket
      |> assign(:results, results)
      |> assign(:media, socket.assigns.media ++ results.entries)

    {:noreply, new_socket}
  end

  defp search_media(socket, c, pagination_opts \\ []) do
    {query, pagination_options} =
      Material.MediaSearch.search_query(Platform.Material.Media, c, socket.assigns.current_user)

    query
    |> Material.MediaSearch.filter_viewable(socket.assigns.current_user)
    |> Material.query_media_paginated(Keyword.merge(pagination_options, pagination_opts))
  end

  def render(assigns) do
    ~H"""
    <section>
      <div class="grid gap-4 grid-cols-1 lg:grid-cols-2 xl:grid-cols-3">
        <%= for media <- @media do %>
          <div
            class="relative group transition"
            x-bind:class="{'opacity-50': faded}"
            x-data="{faded: false}"
          >
            <.media_card media={media} current_user={@current_user} />
            <%= if @show_subscription_button do %>
              <div class="py-1 absolute top-0 right-0 px-2 mt-1 backdrop-blur bg-white/70 shadow rounded-lg transition opacity-0 group-hover:opacity-100 group-focus-within:opacity-100 inline-flex">
                <.live_component
                  module={PlatformWeb.MediaLive.SubscribeButton}
                  media={media}
                  current_user={@current_user}
                  id={"subscription-button-#{media.slug}"}
                  subscribed_label="Unsubscribe"
                  not_subscribed_label="Resubscribe"
                  show_icon={false}
                  js_on_subscribe="faded = false"
                  js_on_unsubscribe="faded = true"
                  subscribed_classes="text-button"
                  not_subscribed_classes="text-button"
                />
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      <%= if length(@media) == 0 do %>
        <div class="text-center mt-12 mx-auto w-full">
          <svg
            class="mx-auto h-16 w-16 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              vector-effect="non-scaling-stroke"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z"
            />
          </svg>
          <h3 class="mt-2 font-medium text-gray-900">No results</h3>
          <p class="mt-1 text-gray-500">No incidents matched this criteria</p>
        </div>
      <% end %>
      <div class="mx-auto mt-8 text-center text-xs">
        <%= if !is_nil(@results.metadata.after) do %>
          <button
            type="button"
            class="text-button"
            phx-click="load_more"
            phx-target={@myself}
            phx-disable-with="Loading..."
          >
            Load More
          </button>
        <% end %>
      </div>
    </section>
    """
  end
end
