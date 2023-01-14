defmodule PlatformWeb.UpdatesLive.PaginatedMediaUpdateFeed do
  use PlatformWeb, :live_component
  alias Platform.Material

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:additional_results_available, true)
      |> assign_new(:restrict_to_user, fn -> nil end)
      |> assign_new(:restrict_to_project_id, fn -> nil end)

    {:ok,
     socket
     |> assign(:pagination_index, 0)
     |> assign(:media, get_feed_media(socket, limit: 50))}
  end

  defp get_feed_media(socket, opts) do
    Material.get_recently_updated_media_paginated(
      Keyword.merge(opts,
        for_user: socket.assigns.current_user,
        restrict_to_user: socket.assigns.restrict_to_user,
        restrict_to_project_id: socket.assigns.restrict_to_project_id
      )
    )
    |> Enum.filter(&Material.Media.can_user_view(&1, socket.assigns.current_user))
  end

  def handle_event("load_more", _params, socket, depth \\ 10) do
    results =
      get_feed_media(socket, offset: 10 * (socket.assigns.pagination_index + 1), limit: 50)

    old_media = socket.assigns.media

    media =
      (socket.assigns.media ++ results)
      |> Enum.uniq_by(& &1.id)
      |> Enum.sort_by(& &1.last_update_time, {:desc, NaiveDateTime})

    new_socket =
      socket
      |> assign(:pagination_index, socket.assigns.pagination_index + 1)
      |> assign(
        :media,
        media
      )
      |> assign(
        :additional_results_available,
        not Enum.empty?(results) or socket.assigns.pagination_index > 10
      )

    # Automatically recurse up to 10 times to try to get more results
    if length(old_media) == length(media) do
      if depth > 0 do
        handle_event("load_more", %{}, new_socket, depth - 1)
      else
        {:noreply, new_socket}
      end
    else
      {:noreply, new_socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <%= if Enum.empty?(@media) do %>
        <div class="text-center mt-8">
          <Heroicons.archive_box class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-medium text-gray-900">No activity to display</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by working on an incident</p>
        </div>
      <% end %>
      <%= for incident <- @media do %>
        <div class="w-full max-w-full group">
          <.media_line_preview media={incident} />
          <ul
            class="card shadow mt-2 cursor-pointer"
            onclick={"window.location = '/incidents/#{incident.slug}'"}
          >
            <% len = min(3, length(incident.updates)) %>
            <%= if length(incident.updates) > 5 do %>
              <div class="relative group word-breaks">
                <span
                  class="absolute top-5 -mt-10 pb-10 left-5 -ml-px h-full w-0.5 border border-dashed border-gray-300"
                  aria-hidden="true"
                >
                </span>
              </div>
            <% end %>
            <%= for {update, idx} <- incident.updates |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime}) |> Enum.take(3) |> Enum.reverse() |> Enum.with_index() do %>
              <.update_entry
                update={update}
                show_line={idx != len - 1}
                show_media={false}
                can_user_change_visibility={false}
                target={@myself}
                socket={@socket}
                profile_ring={false}
                left_indicator={:profile}
                current_user={@current_user}
              />
            <% end %>
          </ul>
          <.link
            href={"/incidents/#{incident.slug}#comment-box"}
            class="text-xs text-neutral-500 mt-2 transition-all hover:text-urge-600 font-medium opacity-0 group-hover:opacity-100 group-focus-within:opacity-100"
          >
            <span x-ref="link">Open incident &rarr;</span>
          </.link>
        </div>
      <% end %>
      <div class="mx-auto mt-4 mb-8 text-center text-xs">
        <%= if @additional_results_available do %>
          <div
            phx-hook="InfiniteScroll"
            id="feed-load-more"
            data-page={@pagination_index}
            phx-target={@myself}
            class="flex items-center justify-around"
          >
            <.loading_spinner />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end